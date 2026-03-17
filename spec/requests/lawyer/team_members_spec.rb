require 'rails_helper'

RSpec.describe "Lawyer::TeamMembers", type: :request do
  let(:team) { create(:lawyer_team) }
  let(:team_leader) {
    create(:lawyer_account,
      password: 'password123',
      password_confirmation: 'password123',
      lawyer_team: team
    ).tap do |leader|
      team.update!(leader_id: leader.id)
    end
  }
  let(:regular_member) {
    create(:lawyer_account,
      password: 'password123',
      password_confirmation: 'password123',
      lawyer_team: team
    )
  }
  
  def sign_in_lawyer(lawyer_account)
    post login_path, params: { 
      phone: lawyer_account.phone, 
      password: 'password123',
      login_type: 'password'
    }
  end

  describe "GET /lawyer/team_members/new" do
    context "when logged in as team leader" do
      before { sign_in_lawyer(team_leader) }

      it "returns http success and shows create form" do
        get new_lawyer_team_member_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('创建团队成员账户')
        expect(response.body).to include(team.name)
      end
    end

    context "when logged in as regular member" do
      before { sign_in_lawyer(regular_member) }

      it "denies access" do
        get new_lawyer_team_member_path
        expect(response).to redirect_to(lawyer_team_path)
        follow_redirect!
        expect(response.body).to include('只有团队负责人可以创建团队成员账户')
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        get new_lawyer_team_member_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "POST /lawyer/team_members" do
    let(:valid_params) {
      {
        lawyer_account: {
          name: '测试成员',
          phone: '13900000000',
          password: 'password123',
          password_confirmation: 'password123',
          role: 'lawyer'
        }
      }
    }

    context "when logged in as team leader" do
      before { sign_in_lawyer(team_leader) }

      it "creates new lawyer account and adds to team" do
        expect {
          post lawyer_team_members_path, params: valid_params
        }.to change(LawyerAccount, :count).by(1)

        new_lawyer = LawyerAccount.last
        expect(new_lawyer.name).to eq('测试成员')
        expect(new_lawyer.lawyer_team_id).to eq(team.id)
        expect(response).to redirect_to(lawyer_team_path)
        follow_redirect!
        expect(response.body).to include('成功为测试成员创建账户并加入团队')
      end

      it "rejects invalid phone format" do
        invalid_params = valid_params.deep_merge(lawyer_account: { phone: '123456' })
        expect {
          post lawyer_team_members_path, params: invalid_params
        }.not_to change(LawyerAccount, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects password mismatch" do
        invalid_params = valid_params.deep_merge(
          lawyer_account: { 
            password: 'password123',
            password_confirmation: 'different' 
          }
        )
        expect {
          post lawyer_team_members_path, params: invalid_params
        }.not_to change(LawyerAccount, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects duplicate phone number" do
        create(:lawyer_account, phone: '13900000000', password: 'password123', password_confirmation: 'password123')
        expect {
          post lawyer_team_members_path, params: valid_params
        }.not_to change(LawyerAccount, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when logged in as regular member" do
      before { sign_in_lawyer(regular_member) }

      it "denies access" do
        expect {
          post lawyer_team_members_path, params: valid_params
        }.not_to change(LawyerAccount, :count)
        expect(response).to redirect_to(lawyer_team_path)
      end
    end
  end
end
