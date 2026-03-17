require 'rails_helper'

RSpec.describe "Admin::BusinessTeamOwnerships", type: :request do
  before { admin_sign_in_as(create(:administrator)) }

  describe "GET /admin/business_team_ownerships" do
    it "returns http success" do
      get admin_business_team_ownerships_path
      expect(response).to be_success_with_view_check('index')
    end
  end

end
