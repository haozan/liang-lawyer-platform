require "rails_helper"

RSpec.describe "CaseAnalytics", type: :request do
  let(:company) { create(:company) }
  let(:lawyer) { create(:lawyer_account, password: 'password123', password_confirmation: 'password123') }
  let(:company_user) { create(:company_user, company: company, password: 'password123', password_confirmation: 'password123') }

  def sign_in_lawyer(lawyer)
    post login_path, params: { 
      phone: lawyer.phone, 
      password: 'password123',
      login_type: 'password'
    }
  end

  def sign_in_company_user(user)
    post login_path, params: { 
      phone: user.phone, 
      password: 'password123',
      login_type: 'password'
    }
  end

  describe "GET /case_analytics/dashboard" do
    context "when user is a lawyer" do
      before { sign_in_lawyer(lawyer) }

      it "returns http success" do
        get dashboard_case_analytics_path
        expect(response).to have_http_status(:success)
      end

      it "shows dashboard for all companies" do
        get dashboard_case_analytics_path
        expect(response.body).to include("全部企业")
        expect(response.body).to include("综合案件数据分析")
      end

      it "filters by company_id when provided" do
        get dashboard_case_analytics_path(company_id: company.id)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(company.name)
      end

      it "filters by date range" do
        get dashboard_case_analytics_path(date_from: 1.month.ago.to_date, date_to: Date.today)
        expect(response).to have_http_status(:success)
      end

      it "supports data comparison" do
        get dashboard_case_analytics_path(
          date_from: 1.month.ago.to_date,
          date_to: Date.today,
          compare_date_from: 2.months.ago.to_date,
          compare_date_to: 1.month.ago.to_date
        )
        expect(response).to have_http_status(:success)
        expect(response.body).to include("数据对比结果")
      end
    end

    context "when user is a company_user" do
      before { sign_in_company_user(company_user) }

      it "returns http success" do
        get dashboard_case_analytics_path
        expect(response).to have_http_status(:success)
      end

      it "shows dashboard only for own company" do
        get dashboard_case_analytics_path
        expect(response.body).to include(company.name)
        expect(response.body).to include("案件数据统计与分析报告")
      end
    end

    context "when user is not authenticated" do
      it "redirects to login" do
        get dashboard_case_analytics_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /case_analytics/export_report" do
    context "when user is a lawyer" do
      before { sign_in_lawyer(lawyer) }

      it "returns CSV file" do
        get export_report_case_analytics_path(format: :csv)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/csv")
        expect(response.headers["Content-Disposition"]).to include("attachment")
        # Check for CSV extension in filename
        expect(response.headers["Content-Disposition"]).to match(/\.csv/)
      end

      it "includes UTF-8 BOM for Excel compatibility" do
        get export_report_case_analytics_path(format: :csv)
        expect(response.body).to start_with("\uFEFF")
      end

      it "includes report header and metadata" do
        get export_report_case_analytics_path(format: :csv, date_from: Date.today, date_to: Date.today)
        expect(response.body).to include("案件数据分析报表")
        expect(response.body).to include("生成时间")
      end
    end

    context "when user is a company_user" do
      before { sign_in_company_user(company_user) }

      it "returns CSV file" do
        get export_report_case_analytics_path(format: :csv)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/csv")
      end
    end

    context "when user is not authenticated" do
      it "redirects to login" do
        get export_report_case_analytics_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "Data Analytics Service Integration" do
    let!(:case1) { create(:case, company: company, status: "filed", filing_at: 10.days.ago) }
    let!(:case2) { create(:case, company: company, status: "closed", filing_at: 5.days.ago, closing_at: 1.day.ago) }
    let!(:case3) { create(:case, company: company, status: "trial", filing_at: 2.days.ago) }

    before { sign_in_lawyer(lawyer) }

    it "displays core KPIs correctly" do
      get dashboard_case_analytics_path(company_id: company.id)
      expect(response.body).to include("案件总数")
      expect(response.body).to include("活跃案件")
      expect(response.body).to include("已归档")
      expect(response.body).to include("完成率")
    end

    it "includes status distribution" do
      get dashboard_case_analytics_path(company_id: company.id)
      expect(response.body).to include("状态分布")
    end

    it "includes trend analysis" do
      get dashboard_case_analytics_path(company_id: company.id)
      expect(response.body).to include("立案趋势分析")
    end

    it "displays urgent alerts when present" do
      # Create an urgent case
      urgent_case = create(:case, company: company, priority: "urgent", status: "preparing")
      get dashboard_case_analytics_path(company_id: company.id)
      expect(response.body).to include("需要立即关注的案件")
    end
  end

  describe "Permission handling" do
    let(:other_company) { create(:company, name: "其他公司_#{SecureRandom.hex(4)}") }

    before { sign_in_company_user(company_user) }

    it "does not allow company_user to view other companies' data" do
      get dashboard_case_analytics_path(company_id: other_company.id)
      expect(response).to redirect_to(dashboard_case_analytics_path)
    end

    it "does not show company selector for company_user" do
      get dashboard_case_analytics_path
      expect(response.body).not_to include("选择企业")
    end
  end
end
