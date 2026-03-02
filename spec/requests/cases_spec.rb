require 'rails_helper'

RSpec.describe "Cases", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { last_or_create(:user) }
  # before { sign_in_as(user) }

  describe "GET /cases" do
    it "returns http success" do
      get cases_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /cases/:id" do
    let(:case_record) { create(:case) }

    it "returns http success" do
      get case_path(case_record)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /cases/new" do
    it "returns http success" do
      get new_case_path
      expect(response).to be_success_with_view_check('new')
    end
  end

  describe "GET /cases/:id/edit" do
    let(:case_record) { create(:case) }

    it "returns http success" do
      get edit_case_path(case_record)
      expect(response).to be_success_with_view_check('edit')
    end
  end

  describe "POST /cases" do
    it "creates a new case" do
      post cases_path, params: { case: attributes_for(:case) }
      expect(response).to be_success_with_view_check
    end
  end


  describe "PATCH /cases/:id" do
    let(:case_record) { create(:case) }

    it "updates the case" do
      patch case_path(case_record), params: { case: attributes_for(:case) }
      expect(response).to be_success_with_view_check
    end
  end
end
