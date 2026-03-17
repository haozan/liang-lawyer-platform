require 'rails_helper'

RSpec.describe "Lawyer::Profiles", type: :request do
  let(:lawyer) { create(:lawyer_account, password: 'password123', password_confirmation: 'password123') }
  
  def sign_in_lawyer(lawyer_account)
    post login_path, params: { 
      phone: lawyer_account.phone, 
      password: 'password123',
      login_type: 'password'
    }
  end

  describe "GET /lawyer/profile/edit" do
    context "when logged in as lawyer" do
      before { sign_in_lawyer(lawyer) }

      it "renders edit page successfully" do
        get edit_lawyer_profile_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        get edit_lawyer_profile_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "PATCH /lawyer/profile" do
    before { sign_in_lawyer(lawyer) }

    context "with valid current password and valid new data" do
      it "updates lawyer account and redirects to login" do
        patch lawyer_profile_path, params: {
          lawyer_account: {
            name: 'Updated Name',
            phone: '13900000001',
            current_password: 'password123',
            password: 'newpassword123',
            password_confirmation: 'newpassword123'
          }
        }

        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq('账户信息已更新，请重新登录')
        
        lawyer.reload
        expect(lawyer.name).to eq('Updated Name')
        expect(lawyer.phone).to eq('13900000001')
        expect(lawyer.authenticate('newpassword123')).to be_truthy
      end

      it "updates only name and phone without changing password" do
        old_password_digest = lawyer.password_digest
        
        patch lawyer_profile_path, params: {
          lawyer_account: {
            name: 'New Name Only',
            phone: '13900000002',
            current_password: 'password123',
            password: '',
            password_confirmation: ''
          }
        }

        expect(response).to redirect_to(login_path)
        lawyer.reload
        expect(lawyer.name).to eq('New Name Only')
        expect(lawyer.phone).to eq('13900000002')
        expect(lawyer.password_digest).to eq(old_password_digest)
      end
    end

    context "with invalid current password" do
      it "renders edit with error message" do
        patch lawyer_profile_path, params: {
          lawyer_account: {
            name: 'Should Not Update',
            current_password: 'wrongpassword',
            password: 'newpassword123',
            password_confirmation: 'newpassword123'
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('当前密码错误')
        
        lawyer.reload
        expect(lawyer.name).not_to eq('Should Not Update')
      end
    end

    context "with invalid new data" do
      it "renders edit with validation errors for invalid phone" do
        patch lawyer_profile_path, params: {
          lawyer_account: {
            name: 'Valid Name',
            phone: 'invalid',
            current_password: 'password123'
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders edit with validation errors for password confirmation mismatch" do
        patch lawyer_profile_path, params: {
          lawyer_account: {
            name: 'Valid Name',
            current_password: 'password123',
            password: 'newpassword123',
            password_confirmation: 'different'
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
