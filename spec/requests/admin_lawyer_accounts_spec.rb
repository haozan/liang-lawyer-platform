require 'rails_helper'

RSpec.describe "Admin::LawyerAccounts", type: :request do
  before { admin_sign_in_as(create(:administrator)) }

  describe "GET /admin/lawyer_accounts" do
    it "returns http success" do
      get admin_lawyer_accounts_path
      expect(response).to be_success_with_view_check('index')
    end
  end

end
