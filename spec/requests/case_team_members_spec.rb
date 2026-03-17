require 'rails_helper'

RSpec.describe "Case team members", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { last_or_create(:user) }
  # before { sign_in_as(user) }

  describe "GET /case_team_members" do
    it "returns http success" do
      get case_team_members_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /case_team_members/:id" do
    let(:case_team_member_record) { create(:case_team_member) }

    it "returns http success" do
      get case_team_member_path(case_team_member_record)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /case_team_members/new" do
    it "returns http success" do
      get new_case_team_member_path
      expect(response).to be_success_with_view_check('new')
    end
  end

  describe "GET /case_team_members/:id/edit" do
    let(:case_team_member_record) { create(:case_team_member) }

    it "returns http success" do
      get edit_case_team_member_path(case_team_member_record)
      expect(response).to be_success_with_view_check('edit')
    end
  end

  describe "POST /case_team_members" do
    it "creates a new case_team_member" do
      post case_team_members_path, params: { case_team_member: attributes_for(:case_team_member) }
      expect(response).to be_success_with_view_check
    end
  end


  describe "PATCH /case_team_members/:id" do
    let(:case_team_member_record) { create(:case_team_member) }

    it "updates the case_team_member" do
      patch case_team_member_path(case_team_member_record), params: { case_team_member: attributes_for(:case_team_member) }
      expect(response).to be_success_with_view_check
    end
  end
end
