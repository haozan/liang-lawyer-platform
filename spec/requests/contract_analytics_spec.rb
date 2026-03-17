require "rails_helper"

RSpec.describe "ContractAnalytics", type: :request do
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

  describe "GET /contract_analytics/dashboard" do
    context "when user is a lawyer" do
      before { sign_in_lawyer(lawyer) }

      it "returns http success" do
        get dashboard_contract_analytics_path
        expect(response).to have_http_status(:success)
      end

      it "shows dashboard for all companies" do
        get dashboard_contract_analytics_path
        expect(response.body).to include("全部企业")
        expect(response.body).to include("综合合同数据分析")
      end

      it "filters by company_id when provided" do
        get dashboard_contract_analytics_path(company_id: company.id)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(company.name)
      end

      it "filters by date range" do
        get dashboard_contract_analytics_path(date_from: 1.month.ago.to_date, date_to: Date.today)
        expect(response).to have_http_status(:success)
      end

      it "supports data comparison" do
        get dashboard_contract_analytics_path(
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
        get dashboard_contract_analytics_path
        expect(response).to have_http_status(:success)
      end

      it "shows dashboard only for own company" do
        get dashboard_contract_analytics_path
        expect(response.body).to include(company.name)
        expect(response.body).to include("合同数据统计与分析报告")
      end
    end

    context "when user is not authenticated" do
      it "redirects to login" do
        get dashboard_contract_analytics_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /contract_analytics/export_report" do
    context "when user is a lawyer" do
      before { sign_in_lawyer(lawyer) }

      it "returns CSV file" do
        get export_report_contract_analytics_path(format: :csv)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/csv")
        expect(response.headers["Content-Disposition"]).to include("attachment")
        # Check for CSV extension in filename
        expect(response.headers["Content-Disposition"]).to match(/\.csv/)
      end

      it "includes UTF-8 BOM for Excel compatibility" do
        get export_report_contract_analytics_path(format: :csv)
        expect(response.body).to start_with("\uFEFF")
      end

      it "includes report header and metadata" do
        get export_report_contract_analytics_path(format: :csv, date_from: Date.today, date_to: Date.today)
        expect(response.body).to include("合同数据分析报表")
        expect(response.body).to include("生成时间")
      end
    end

    context "when user is a company_user" do
      before { sign_in_company_user(company_user) }

      it "returns CSV file" do
        get export_report_contract_analytics_path(format: :csv)
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include("text/csv")
        # Check for CSV extension in filename
        expect(response.headers["Content-Disposition"]).to match(/\.csv/)
      end
    end

    context "when user is not authenticated" do
      it "redirects to login" do
        get export_report_contract_analytics_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "Data Analytics Service Integration" do
    let!(:contract1) { create(:contract, company: company, status: "active", contract_amount: 100000, signed_at: 10.days.ago) }
    let!(:contract2) { create(:contract, company: company, status: "completed", contract_amount: 500000, signed_at: 5.days.ago) }
    let!(:contract3) { create(:contract, company: company, status: "active", contract_amount: 200000, signed_at: 2.days.ago) }

    before { sign_in_lawyer(lawyer) }

    it "displays core KPIs correctly" do
      get dashboard_contract_analytics_path(company_id: company.id)
      expect(response.body).to include("合同总数")
      expect(response.body).to include("执行中")
      expect(response.body).to include("已完成")
      expect(response.body).to include("异常合同")
    end

    it "displays amount statistics" do
      get dashboard_contract_analytics_path(company_id: company.id)
      expect(response.body).to include("金额统计")
      expect(response.body).to include("合同总金额")
    end

    it "displays lawyer review statistics" do
      get dashboard_contract_analytics_path(company_id: company.id)
      expect(response.body).to include("律师审查统计")
      expect(response.body).to include("已审查")
      expect(response.body).to include("待审查")
    end

    it "includes status distribution" do
      get dashboard_contract_analytics_path(company_id: company.id)
      expect(response.body).to include("状态分布")
    end

    it "includes trend analysis" do
      get dashboard_contract_analytics_path(company_id: company.id)
      expect(response.body).to include("签订趋势分析")
    end

    it "displays risk alerts when present" do
      # Create a high-risk contract
      risky_contract = create(:contract, company: company, legal_risk_level: "高", status: "active")
      get dashboard_contract_analytics_path(company_id: company.id)
      expect(response.body).to include("风险提醒")
    end
  end

  describe "Permission handling" do
    let(:other_company) { create(:company, name: "其他公司_#{SecureRandom.hex(4)}") }

    before { sign_in_company_user(company_user) }

    it "does not allow company_user to view other companies' data" do
      get dashboard_contract_analytics_path(company_id: other_company.id)
      expect(response).to redirect_to(dashboard_contract_analytics_path)
    end

    it "does not show company selector for company_user" do
      get dashboard_contract_analytics_path
      expect(response.body).not_to include("选择企业")
    end
  end

  describe "Amount Range Distribution" do
    before do
      sign_in_lawyer(lawyer)
      create(:contract, company: company, contract_amount: 50000)
      create(:contract, company: company, contract_amount: 200000)
      create(:contract, company: company, contract_amount: 700000)
      create(:contract, company: company, contract_amount: 2000000)
      create(:contract, company: company, contract_amount: 6000000)
    end

    it "displays amount range distribution" do
      get dashboard_contract_analytics_path(company_id: company.id)
      expect(response.body).to include("金额区间分布")
      expect(response.body).to include("10万以下")
      expect(response.body).to include("10-50万")
      expect(response.body).to include("50-100万")
      expect(response.body).to include("100-500万")
      expect(response.body).to include("500万以上")
    end
  end
end
