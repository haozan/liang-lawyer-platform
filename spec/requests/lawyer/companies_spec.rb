require 'rails_helper'

RSpec.describe "Lawyer/companies", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { last_or_create(:user) }
  # before { sign_in_as(user) }

  describe "GET /lawyer/companies" do
    it "returns http success" do
      get lawyer_companies_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /lawyer/companies/new" do
    it "returns http success" do
      get new_lawyer_company_path
      expect(response).to be_success_with_view_check('new')
    end
  end

  describe "GET /lawyer/companies/:id/edit" do
    let(:company_record) { create(:company) }

    it "returns http success" do
      get edit_lawyer_company_path(company_record)
      expect(response).to be_success_with_view_check('edit')
    end
  end

  describe "POST /lawyer/companies" do
    it "creates a new company" do
      post lawyer_companies_path, params: { company: attributes_for(:company) }
      expect(response).to be_success_with_view_check
    end
  end


  describe "PATCH /lawyer/companies/:id" do
    let(:company_record) { create(:company) }

    it "updates the company" do
      patch lawyer_company_path(company_record), params: { company: attributes_for(:company) }
      expect(response).to be_success_with_view_check
    end
  end
end
