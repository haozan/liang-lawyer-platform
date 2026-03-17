require 'rails_helper'

RSpec.describe "Major issue analytics", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { last_or_create(:user) }
  # before { sign_in_as(user) }

  describe "GET /major_issue_analytics/dashboard" do
    it "returns http success" do
      get dashboard_major_issue_analytics_path
      expect(response).to be_success_with_view_check('dashboard')
    end
  end

end
