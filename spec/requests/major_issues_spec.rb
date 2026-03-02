require 'rails_helper'

RSpec.describe "Major issues", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { last_or_create(:user) }
  # before { sign_in_as(user) }

  describe "GET /major_issues" do
    it "returns http success" do
      get major_issues_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /major_issues/:id" do
    let(:major_issue_record) { create(:major_issue) }

    it "returns http success" do
      get major_issue_path(major_issue_record)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /major_issues/new" do
    it "returns http success" do
      get new_major_issue_path
      expect(response).to be_success_with_view_check('new')
    end
  end

  describe "GET /major_issues/:id/edit" do
    let(:major_issue_record) { create(:major_issue) }

    it "returns http success" do
      get edit_major_issue_path(major_issue_record)
      expect(response).to be_success_with_view_check('edit')
    end
  end

  describe "POST /major_issues" do
    it "creates a new major_issue" do
      post major_issues_path, params: { major_issue: attributes_for(:major_issue) }
      expect(response).to be_success_with_view_check
    end
  end


  describe "PATCH /major_issues/:id" do
    let(:major_issue_record) { create(:major_issue) }

    it "updates the major_issue" do
      patch major_issue_path(major_issue_record), params: { major_issue: attributes_for(:major_issue) }
      expect(response).to be_success_with_view_check
    end
  end
end
