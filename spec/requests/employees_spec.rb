require 'rails_helper'

RSpec.describe "Employees", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { last_or_create(:user) }
  # before { sign_in_as(user) }

  describe "GET /employees" do
    it "returns http success" do
      get employees_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /employees/:id" do
    let(:employee_record) { create(:employee) }

    it "returns http success" do
      get employee_path(employee_record)
      expect(response).to be_success_with_view_check('show')
    end
  end

  describe "GET /employees/new" do
    it "returns http success" do
      get new_employee_path
      expect(response).to be_success_with_view_check('new')
    end
  end

  describe "GET /employees/:id/edit" do
    let(:employee_record) { create(:employee) }

    it "returns http success" do
      get edit_employee_path(employee_record)
      expect(response).to be_success_with_view_check('edit')
    end
  end

  describe "POST /employees" do
    it "creates a new employee" do
      post employees_path, params: { employee: attributes_for(:employee) }
      expect(response).to be_success_with_view_check
    end
  end


  describe "PATCH /employees/:id" do
    let(:employee_record) { create(:employee) }

    it "updates the employee" do
      patch employee_path(employee_record), params: { employee: attributes_for(:employee) }
      expect(response).to be_success_with_view_check
    end
  end
end
