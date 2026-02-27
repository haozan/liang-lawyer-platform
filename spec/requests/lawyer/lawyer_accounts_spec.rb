require 'rails_helper'

RSpec.describe "Lawyer/lawyer accounts", type: :request do
  # Lawyer authentication required
  let(:lawyer) { last_or_create(:lawyer_account) }
  
  before do
    # Sign in as lawyer
    session_hash = {
      current_lawyer_id: lawyer.id,
      user_type: 'lawyer'
    }
    allow_any_instance_of(Lawyer::LawyerAccountsController).to receive(:session).and_return(session_hash)
  end

  describe "GET /lawyer/lawyer_accounts" do
    it "returns http success" do
      get lawyer_lawyer_accounts_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /lawyer/lawyer_accounts/new" do
    it "returns http success" do
      get new_lawyer_lawyer_account_path
      expect(response).to be_success_with_view_check('new')
    end
  end

  describe "GET /lawyer/lawyer_accounts/:id/edit" do
    let(:lawyer_account_record) { create(:lawyer_account) }

    it "returns http success" do
      get edit_lawyer_lawyer_account_path(lawyer_account_record)
      expect(response).to be_success_with_view_check('edit')
    end
  end

  describe "POST /lawyer/lawyer_accounts" do
    it "creates a new lawyer_account" do
      lawyer_params = {
        name: '新律师',
        email: "new_lawyer_#{rand(10000)}@example.com",
        password: 'password123',
        password_confirmation: 'password123'
      }
      
      expect {
        post lawyer_lawyer_accounts_path, params: { lawyer_account: lawyer_params }
      }.to change(LawyerAccount, :count).by(1)
      
      expect(response).to redirect_to(lawyer_lawyer_accounts_path)
    end
  end

  describe "PATCH /lawyer/lawyer_accounts/:id" do
    let(:lawyer_account_record) { create(:lawyer_account) }

    it "updates the lawyer_account" do
      patch lawyer_lawyer_account_path(lawyer_account_record), params: {
        lawyer_account: { name: '更新名称' }
      }
      expect(response).to redirect_to(lawyer_lawyer_accounts_path)
    end
  end
end
