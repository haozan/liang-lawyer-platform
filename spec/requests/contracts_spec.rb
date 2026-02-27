require 'rails_helper'

RSpec.describe "Contracts", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { last_or_create(:user) }
  # before { sign_in_as(user) }

  describe "GET /contracts" do
    it "returns http success" do
      get contracts_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /contracts/:id" do
    let(:contract_record) { create(:contract) }

    it "returns http success" do
      get contract_path(contract_record)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /contracts/new" do
    it "returns http success" do
      get new_contract_path
      expect(response).to be_success_with_view_check('new')
    end
  end

  describe "GET /contracts/:id/edit" do
    let(:contract_record) { create(:contract) }

    it "returns http success" do
      get edit_contract_path(contract_record)
      expect(response).to be_success_with_view_check('edit')
    end
  end

  describe "POST /contracts" do
    it "creates a new contract" do
      post contracts_path, params: { contract: attributes_for(:contract) }
      expect(response).to be_success_with_view_check
    end
  end


  describe "PATCH /contracts/:id" do
    let(:contract_record) { create(:contract) }

    it "updates the contract" do
      patch contract_path(contract_record), params: { contract: attributes_for(:contract) }
      expect(response).to be_success_with_view_check
    end
  end
end
