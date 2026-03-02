require 'rails_helper'

RSpec.describe "Lawyer::CompanyAccounts", type: :request do
  let(:lawyer) { LawyerAccount.create!(name: '测试律师', email: 'test@lawyer.com', password: 'password123') }
  let(:company) { Company.create!(name: '测试企业') }
  
  before do
    # Simulate lawyer login
    allow_any_instance_of(ApplicationController).to receive(:current_lawyer).and_return(lawyer)
    allow_any_instance_of(ApplicationController).to receive(:require_lawyer).and_return(true)
  end

  describe "GET /lawyer/company_accounts" do
    it "显示企业账户管理页面" do
      get lawyer_company_accounts_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /lawyer/company_accounts" do
    let(:valid_attributes) do
      {
        company_id: company.id,
        company_user: {
          name: '测试用户',
          phone: '13800138000',
          password: 'password123',
          password_confirmation: 'password123',
          role: 'employee'
        }
      }
    end

    it "创建企业账户成功" do
      expect {
        post lawyer_company_accounts_path, params: valid_attributes
      }.to change(CompanyUser, :count).by(1)
      
      expect(response).to redirect_to(lawyer_company_accounts_path)
      follow_redirect!
      expect(response.body).to include('企业账号创建成功')
    end

    it "创建失败时显示错误信息" do
      invalid_attributes = valid_attributes.deep_dup
      invalid_attributes[:company_user][:phone] = ''
      
      expect {
        post lawyer_company_accounts_path, params: invalid_attributes
      }.not_to change(CompanyUser, :count)
      
      expect(response).to redirect_to(lawyer_company_accounts_path)
    end
  end

  describe "PATCH /lawyer/company_accounts/:id" do
    let(:company_user) { company.company_users.create!(name: '原用户', phone: '13900139000', password: 'oldpass123', role: 'employee') }

    it "更新账户密码成功" do
      patch lawyer_company_account_path(company_user), params: {
        company_user: {
          password: 'newpass123',
          password_confirmation: 'newpass123'
        }
      }
      
      expect(response).to redirect_to(lawyer_company_accounts_path)
      follow_redirect!
      expect(response.body).to include('账号密码已重置')
      
      # Verify password was updated
      company_user.reload
      expect(company_user.authenticate('newpass123')).to be_truthy
    end
  end

  describe "DELETE /lawyer/company_accounts/:id" do
    let!(:company_user) { company.company_users.create!(name: '待删除用户', phone: '13700137000', password: 'pass123', role: 'employee') }

    it "删除企业账户成功" do
      expect {
        delete lawyer_company_account_path(company_user)
      }.to change(CompanyUser, :count).by(-1)
      
      expect(response).to redirect_to(lawyer_company_accounts_path)
      follow_redirect!
      expect(response.body).to include('企业账号已删除')
    end
  end
end
