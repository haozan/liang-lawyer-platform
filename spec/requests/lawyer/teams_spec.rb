require 'rails_helper'

RSpec.describe "Lawyer::Teams", type: :request do
  let(:team) { create(:lawyer_team) }
  let(:lawyer) { 
    create(:lawyer_account, 
      password: 'password123', 
      password_confirmation: 'password123',
      lawyer_team: team
    ) 
  }
  let(:team_leader) {
    create(:lawyer_account,
      password: 'password123',
      password_confirmation: 'password123',
      lawyer_team: team
    ).tap do |leader|
      team.update!(leader_id: leader.id)
    end
  }
  
  def sign_in_lawyer(lawyer_account)
    post login_path, params: { 
      phone: lawyer_account.phone, 
      password: 'password123',
      login_type: 'password'
    }
  end

  describe "GET /lawyer/team" do
    context "when logged in as lawyer with team" do
      before { sign_in_lawyer(lawyer) }

      it "returns http success and shows team info" do
        get lawyer_team_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('我的团队')
        expect(response.body).to include('团队信息')
        expect(response.body).to include(team.name)
      end
      
      it "displays team members" do
        get lawyer_team_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('团队成员')
        expect(response.body).to include(lawyer.name)
      end
      
      it "displays business statistics" do
        get lawyer_team_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('团队合同')
        expect(response.body).to include('团队案件')
        expect(response.body).to include('重大事项')
      end
      
      it "does not show member management buttons for non-leader" do
        get lawyer_team_path
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include('添加成员')
        expect(response.body).not_to include('操作')
      end
    end

    context "when logged in as team leader" do
      before { sign_in_lawyer(team_leader) }
      
      it "shows member management buttons" do
        get lawyer_team_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('添加成员')
        expect(response.body).to include('操作')
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        get lawyer_team_path
        expect(response).to redirect_to(login_path)
      end
    end
    
    context "when lawyer has no team" do
      let(:lawyer_without_team) { 
        create(:lawyer_account, 
          password: 'password123', 
          password_confirmation: 'password123',
          lawyer_team: nil
        ) 
      }
      
      before { sign_in_lawyer(lawyer_without_team) }
      
      it "redirects with alert message" do
        get lawyer_team_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('您尚未加入任何团队，请联系管理员')
      end
    end
  end
  
  describe "POST /lawyer/team/add_member" do
    let(:available_lawyer) { create(:lawyer_account, lawyer_team: nil, password: 'password123', password_confirmation: 'password123') }
    
    context "when logged in as team leader" do
      before { sign_in_lawyer(team_leader) }
      
      it "adds lawyer to team" do
        post add_member_lawyer_team_path(lawyer_id: available_lawyer.id)
        
        expect(response).to redirect_to(lawyer_team_path)
        expect(flash[:notice]).to include("已成功将#{available_lawyer.name}添加到团队")
        
        available_lawyer.reload
        expect(available_lawyer.lawyer_team_id).to eq(team.id)
      end
      
      it "rejects lawyer already in another team" do
        other_team = create(:lawyer_team)
        other_lawyer = create(:lawyer_account, lawyer_team: other_team, password: 'password123', password_confirmation: 'password123')
        
        post add_member_lawyer_team_path(lawyer_id: other_lawyer.id)
        
        expect(response).to redirect_to(lawyer_team_path)
        expect(flash[:alert]).to include('已在其他团队中')
      end
    end
    
    context "when logged in as non-leader" do
      before { sign_in_lawyer(lawyer) }
      
      it "denies access" do
        post add_member_lawyer_team_path(lawyer_id: available_lawyer.id)
        
        expect(response).to redirect_to(lawyer_team_path)
        expect(flash[:alert]).to eq('只有团队负责人可以管理成员')
      end
    end
  end
  
  describe "DELETE /lawyer/team/remove_member" do
    let(:team_member) { create(:lawyer_account, lawyer_team: team, password: 'password123', password_confirmation: 'password123') }
    
    context "when logged in as team leader" do
      before { sign_in_lawyer(team_leader) }
      
      it "removes lawyer from team" do
        delete remove_member_lawyer_team_path(lawyer_id: team_member.id)
        
        expect(response).to redirect_to(lawyer_team_path)
        expect(flash[:notice]).to include("已将#{team_member.name}移出团队")
        
        team_member.reload
        expect(team_member.lawyer_team_id).to be_nil
      end
      
      it "prevents removing team leader" do
        delete remove_member_lawyer_team_path(lawyer_id: team_leader.id)
        
        expect(response).to redirect_to(lawyer_team_path)
        expect(flash[:alert]).to eq('不能移除团队负责人')
        
        team_leader.reload
        expect(team_leader.lawyer_team_id).to eq(team.id)
      end
    end
    
    context "when logged in as non-leader" do
      before { sign_in_lawyer(lawyer) }
      
      it "denies access" do
        delete remove_member_lawyer_team_path(lawyer_id: team_member.id)
        
        expect(response).to redirect_to(lawyer_team_path)
        expect(flash[:alert]).to eq('只有团队负责人可以管理成员')
      end
    end
  end
end
