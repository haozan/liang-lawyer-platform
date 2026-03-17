require 'rails_helper'

RSpec.describe "Admin::ContractTags", type: :request do
  before { admin_sign_in_as(create(:administrator)) }

  describe "GET /admin/contract_tags" do
    it "returns http success" do
      get admin_contract_tags_path
      expect(response).to be_success_with_view_check('index')
    end
  end

end
