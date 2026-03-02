require 'rails_helper'

RSpec.describe "Workbench", type: :request do
  let(:company) { create(:company) }
  let(:boss) { create(:company_user, :boss, company: company) }
  let(:employee) { create(:company_user, :employee, company: company) }
  let(:executive) { create(:company_user, :executive, company: company) }

  describe "GET /workbench" do
    context "when logged in as boss" do
      before do
        post login_path, params: { phone: boss.phone, password: 'password123' }
      end

      it "returns http success" do
        get workbench_index_path
        expect(response).to have_http_status(:success)
      end

      it "displays company name" do
        get workbench_index_path
        expect(response.body).to include(company.name)
      end

      it "shows control panel button for boss" do
        get workbench_index_path
        expect(response.body).to include('控制面板')
      end
    end

    context "when logged in as employee" do
      before do
        post login_path, params: { phone: employee.phone, password: 'password123' }
      end

      it "returns http success" do
        get workbench_index_path
        expect(response).to have_http_status(:success)
      end

      it "does not show control panel button for employee" do
        get workbench_index_path
        expect(response.body).not_to include('控制面板')
      end
    end

    context "when logged in as executive" do
      before do
        post login_path, params: { phone: executive.phone, password: 'password123' }
      end

      it "returns http success" do
        get workbench_index_path
        expect(response).to have_http_status(:success)
      end

      it "does not show control panel button for executive" do
        get workbench_index_path
        expect(response.body).not_to include('控制面板')
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
