require 'rails_helper'

RSpec.describe "Workbench", type: :request do
  let(:company) { create(:company) }
  let(:boss) { create(:company_user, :boss, company: company) }
  let(:employee) { create(:company_user, :employee, company: company) }
  let(:executive) { create(:company_user, :executive, company: company) }

  describe "GET /workbench" do
    context "when logged in as boss" do
      before do
        # Ensure test data is created first
        company
        boss
        post login_path, params: { phone: boss.phone, password: 'password123', login_type: 'password' }
        follow_redirect!
      end

      it "returns http success" do
        get workbench_index_path
        expect(response).to have_http_status(:success)
      end

      it "displays company name" do
        get workbench_index_path
        expect(response.body).to include(company.name)
      end
    end

    context "when logged in as employee" do
      before do
        company
        employee
        post login_path, params: { phone: employee.phone, password: 'password123', login_type: 'password' }
        follow_redirect!
      end

      it "returns http success" do
        get workbench_index_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when logged in as executive" do
      before do
        company
        executive
        post login_path, params: { phone: executive.phone, password: 'password123', login_type: 'password' }
        follow_redirect!
      end

      it "returns http success" do
        get workbench_index_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when not logged in" do
      it "redirects to login page" do
        get workbench_index_path
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
