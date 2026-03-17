require 'rails_helper'

RSpec.describe "Contract risks", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { last_or_create(:user) }
  # before { sign_in_as(user) }

  describe "GET /contract_risks/dashboard" do
    it "returns http success" do
      get dashboard_contract_risks_path
      expect(response).to be_success_with_view_check('dashboard')
    end
  end

end
