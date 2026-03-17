require 'rails_helper'

RSpec.describe "LawyerFeeAnalytics", type: :request do
  let(:lawyer_team) { create(:lawyer_team) }
  let(:lawyer_account) { create(:lawyer_account, lawyer_team: lawyer_team, role: 'lawyer', password: 'password123', password_confirmation: 'password123') }
  let(:company_user) { create(:company_user, password: 'password123', password_confirmation: 'password123') }
  let(:company) { company_user.company }
  
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
  
  # 创建测试数据
  before do
    # 为公司创建案件，部分案件有律师费
    @case_with_fee = create(:case, 
      company: company, 
      lawyer_fee: 100_000,
      lawyer_fee_payment_status: 'completed',
      lawyer_fee_received: 100_000,
      lawyer_fee_received_at: Date.today
    )
    
    @case_partial_paid = create(:case,
      company: company,
      lawyer_fee: 200_000,
      lawyer_fee_payment_status: 'partial',
      lawyer_fee_received: 100_000,
      lawyer_fee_received_at: Date.today
    )
    
    @case_pending = create(:case,
      company: company,
      lawyer_fee: 50_000,
      lawyer_fee_payment_status: 'pending'
    )
    
    # 为案件添加团队成员
    create(:case_team_member, case: @case_with_fee, lawyer_account: lawyer_account, role: 'lead_lawyer')
    create(:case_team_member, case: @case_partial_paid, lawyer_account: lawyer_account, role: 'lead_lawyer')
    create(:case_team_member, case: @case_pending, lawyer_account: lawyer_account, role: 'assistant_lawyer')
    
    # 设置公司的律师团队
    company.update(lawyer_team: lawyer_team)
  end
  
  describe "权限控制" do
    context "when not logged in" do
      it "redirects to login page" do
        get dashboard_lawyer_fee_analytics_path
        expect(response).to redirect_to(login_path)
      end
    end
    
    context "when logged in as company user" do
      before { sign_in_company_user(company_user) }
      
      it "redirects to login page with error message" do
        get dashboard_lawyer_fee_analytics_path
        expect(response).to redirect_to(login_path)
      end
    end
    
    context "when logged in as lawyer" do
      before { sign_in_lawyer(lawyer_account) }
      
      it "allows access to dashboard" do
        get dashboard_lawyer_fee_analytics_path
        expect(response).to have_http_status(:success)
      end
    end
  end
  
  describe "GET /lawyer_fee_analytics/dashboard" do
    before { sign_in_lawyer(lawyer_account) }
    
    it "returns http success" do
      get dashboard_lawyer_fee_analytics_path
      expect(response).to have_http_status(:success)
    end
    
    it "displays lawyer fee analytics dashboard" do
      get dashboard_lawyer_fee_analytics_path
      expect(response.body).to include('律师费数据分析仪表盘')
      expect(response.body).to include('律师费总收入')
      expect(response.body).to include('已回款金额')
      expect(response.body).to include('回款率')
    end
    
    it "displays core KPIs" do
      get dashboard_lawyer_fee_analytics_path
      expect(response.body).to include('律师费总收入')
      expect(response.body).to include('已回款金额')
      expect(response.body).to include('待回款金额')
    end
    
    it "displays data correctly" do
      get dashboard_lawyer_fee_analytics_path
      expect(response.body).to include('律师工作量统计')
      expect(response.body).to include('企业客户律师费排行')
    end
    
    context "with company filter" do
      it "filters cases by company" do
        get dashboard_lawyer_fee_analytics_path, params: { company_id: company.id }
        expect(response).to have_http_status(:success)
        expect(response.body).to include(company.name)
      end
    end
    
    context "with date range filter" do
      it "accepts date range parameters" do
        get dashboard_lawyer_fee_analytics_path, params: {
          date_from: 30.days.ago.to_date,
          date_to: Date.today
        }
        expect(response).to have_http_status(:success)
      end
    end
  end
  
  describe "GET /lawyer_fee_analytics/export_detailed" do
    before { sign_in_lawyer(lawyer_account) }
    
    it "returns CSV file" do
      get export_detailed_lawyer_fee_analytics_path
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('text/csv; charset=utf-8')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Disposition']).to include('.csv')
    end
    
    it "includes correct CSV headers" do
      get export_detailed_lawyer_fee_analytics_path
      csv_content = response.body.force_encoding('UTF-8')
      expect(csv_content).to include('案件名称')
      expect(csv_content).to include('律师费金额')
      expect(csv_content).to include('付款状态')
    end
  end
  
  describe "GET /lawyer_fee_analytics/export_lawyer_summary" do
    before { sign_in_lawyer(lawyer_account) }
    
    it "returns CSV file" do
      get export_lawyer_summary_lawyer_fee_analytics_path
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('text/csv; charset=utf-8')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Disposition']).to include('.csv')
    end
    
    it "includes lawyer workload data" do
      get export_lawyer_summary_lawyer_fee_analytics_path
      csv_content = response.body.force_encoding('UTF-8')
      expect(csv_content).to include('律师姓名')
      expect(csv_content).to include('参与案件数')
      expect(csv_content).to include('主办案件总律师费')
    end
  end
  
  describe "GET /lawyer_fee_analytics/export_company_summary" do
    before { sign_in_lawyer(lawyer_account) }
    
    it "returns CSV file" do
      get export_company_summary_lawyer_fee_analytics_path
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('text/csv; charset=utf-8')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Disposition']).to include('.csv')
    end
    
    it "includes company rankings data" do
      get export_company_summary_lawyer_fee_analytics_path
      csv_content = response.body.force_encoding('UTF-8')
      expect(csv_content).to include('企业名称')
      expect(csv_content).to include('律师费总额')
    end
  end
end
