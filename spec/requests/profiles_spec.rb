require 'rails_helper'

RSpec.describe "Profiles", type: :request do
  let(:company) { create(:company) }
  let(:company_user) { create(:company_user, company: company, password: 'password123', password_confirmation: 'password123') }
  
  def sign_in_company_user(user)
    post login_path, params: { 
      phone: user.phone, 
      password: 'password123',
      login_type: 'password'
    }
  end

  describe "GET /profile/edit" do
    context "when logged in as company user" do
      before { sign_in_company_user(company_user) }

      it "renders edit page successfully" do
        get edit_profile_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        get edit_profile_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "PATCH /profile" do
    before { sign_in_company_user(company_user) }

    context "with valid current password and valid new data" do
      it "updates company user account and redirects to login" do
        patch profile_path, params: {
          company_user: {
            name: 'Updated Name',
            phone: '13900000003',
            current_password: 'password123',
            password: 'newpassword123',
            password_confirmation: 'newpassword123'
          }
        }

        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to eq('账户信息已更新，请重新登录')
        
        company_user.reload
        expect(company_user.name).to eq('Updated Name')
        expect(company_user.phone).to eq('13900000003')
        expect(company_user.authenticate('newpassword123')).to be_truthy
      end

      it "updates only name and phone without changing password" do
        old_password_digest = company_user.password_digest
        
        patch profile_path, params: {
          company_user: {
            name: 'New Name Only',
            phone: '13900000004',
            current_password: 'password123',
            password: '',
            password_confirmation: ''
          }
        }

        expect(response).to redirect_to(login_path)
        company_user.reload
        expect(company_user.name).to eq('New Name Only')
        expect(company_user.phone).to eq('13900000004')
        expect(company_user.password_digest).to eq(old_password_digest)
      end
    end

    context "with invalid current password" do
      it "renders edit with error message" do
        patch profile_path, params: {
          company_user: {
            name: 'Should Not Update',
            current_password: 'wrongpassword',
            password: 'newpassword123',
            password_confirmation: 'newpassword123'
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('当前密码错误')
        
        company_user.reload
        expect(company_user.name).not_to eq('Should Not Update')
      end
    end

    context "with invalid new data" do
      it "renders edit with validation errors for invalid phone" do
        patch profile_path, params: {
          company_user: {
            name: 'Valid Name',
            phone: 'invalid',
            current_password: 'password123'
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders edit with validation errors for password confirmation mismatch" do
        patch profile_path, params: {
          company_user: {
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
