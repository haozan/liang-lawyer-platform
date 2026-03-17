require 'rails_helper'

RSpec.describe "Admin::DataAccessLogs", type: :request do
  before { admin_sign_in_as(create(:administrator)) }

  describe "GET /admin/data_access_logs" do
    it "returns http success" do
      get admin_data_access_logs_path
      expect(response).to be_success_with_view_check('index')
    end
  end

end
