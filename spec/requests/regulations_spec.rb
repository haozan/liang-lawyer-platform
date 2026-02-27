require 'rails_helper'

RSpec.describe "Regulations", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { last_or_create(:user) }
  # before { sign_in_as(user) }

  describe "GET /regulations" do
    it "returns http success" do
      get regulations_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /regulations/:id" do
    let(:regulation_record) { create(:regulation) }

    it "returns http success" do
      get regulation_path(regulation_record)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /regulations/new" do
    it "returns http success" do
      get new_regulation_path
      expect(response).to be_success_with_view_check('new')
    end
  end

  describe "GET /regulations/:id/edit" do
    let(:regulation_record) { create(:regulation) }

    it "returns http success" do
      get edit_regulation_path(regulation_record)
      expect(response).to be_success_with_view_check('edit')
    end
  end

  describe "POST /regulations" do
    it "creates a new regulation" do
      post regulations_path, params: { regulation: attributes_for(:regulation) }
      expect(response).to be_success_with_view_check
    end
  end


  describe "PATCH /regulations/:id" do
    let(:regulation_record) { create(:regulation) }

    it "updates the regulation" do
      patch regulation_path(regulation_record), params: { regulation: attributes_for(:regulation) }
      expect(response).to be_success_with_view_check
    end
  end
end
