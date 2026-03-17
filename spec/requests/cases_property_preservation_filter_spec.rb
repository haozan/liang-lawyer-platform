require 'rails_helper'

RSpec.describe "案件财产保全筛选功能", type: :request do
  let!(:lawyer_team) { LawyerTeam.create!(name: "测试团队", code: "TEST_TEAM", leader: nil) }
  let!(:lawyer) { LawyerAccount.create!(phone: "13800000001", password: "888888", name: "测试律师", lawyer_team: lawyer_team) }
  let!(:company) { Company.create!(name: "测试企业", status: "active", lawyer_team: lawyer_team) }
  
  before do
    # 设置 Current.lawyer_account 以便 Case 创建时自动建立团队归属
    Current.lawyer_account = lawyer
    
    # 模拟律师登录（用于session设置）
    allow_any_instance_of(ApplicationController).to receive(:current_lawyer_account).and_return(lawyer)
    allow_any_instance_of(ApplicationController).to receive(:current_lawyer).and_return(lawyer)
    allow_any_instance_of(ApplicationController).to receive(:lawyer?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:company_user?).and_return(false)
  end
  
  after do
    # 清理 Current
    Current.lawyer_account = nil
  end
  
  # 创建不同类型的案件
  let!(:case_without_pp) do
    Case.create!(
      name: "无财产保全案件",
      case_number: "TEST001",
      case_type: "合同纠纷",
      status: "filed",
      filing_at: Date.today,
      company: company
    )
  end
  
  let!(:case_with_expired_pp) do
    Case.create!(
      name: "已过期财产保全案件",
      case_number: "TEST002",
      case_type: "侵权纠纷",
      status: "trial",
      filing_at: Date.today,
      property_preservation_applied_at: 60.days.ago,
      property_preservation_deadline: 10.days.ago,
      company: company
    )
  end
  
  let!(:case_with_active_pp_far) do
    Case.create!(
      name: "有效财产保全案件（90天后到期）",
      case_number: "TEST003",
      case_type: "劳动纠纷",
      status: "trial",
      filing_at: Date.today,
      property_preservation_applied_at: Date.today,
      property_preservation_deadline: 90.days.from_now,
      company: company
    )
  end
  
  let!(:case_with_active_pp_near) do
    Case.create!(
      name: "有效财产保全案件（30天后到期）",
      case_number: "TEST004",
      case_type: "买卖合同纠纷",
      status: "trial",
      filing_at: Date.today,
      property_preservation_applied_at: Date.today,
      property_preservation_deadline: 30.days.from_now,
      company: company
    )
  end
  
  let!(:case_with_active_pp_soon) do
    Case.create!(
      name: "有效财产保全案件（7天后到期）",
      case_number: "TEST005",
      case_type: "股权纠纷",
      status: "trial",
      filing_at: Date.today,
      property_preservation_applied_at: Date.today,
      property_preservation_deadline: 7.days.from_now,
      company: company
    )
  end
  
  describe "GET /cases with property preservation filter" do
    context "when filtering all cases with property preservation" do
      it "returns only cases that have property_preservation_deadline set" do
        get '/cases', params: { has_property_preservation: '1' }
        
        expect(response).to have_http_status(:success)
        
        # 应该返回所有设置了财产保全的案件（包括已过期的）
        expect(response.body).to include("已过期财产保全案件")
        expect(response.body).to include("有效财产保全案件（90天后到期）")
        expect(response.body).to include("有效财产保全案件（30天后到期）")
        expect(response.body).to include("有效财产保全案件（7天后到期）")
        
        # 不应该返回没有财产保全的案件
        expect(response.body).not_to include("无财产保全案件")
      end
    end
    
    context "when filtering active property preservation only" do
      it "returns only cases with valid (not expired) property preservation" do
        get '/cases', params: { has_property_preservation: 'active' }
        
        expect(response).to have_http_status(:success)
        
        # 应该只返回有效的财产保全案件
        expect(response.body).to include("有效财产保全案件（90天后到期）")
        expect(response.body).to include("有效财产保全案件（30天后到期）")
        expect(response.body).to include("有效财产保全案件（7天后到期）")
        
        # 不应该返回已过期的或没有财产保全的案件
        expect(response.body).not_to include("已过期财产保全案件")
        expect(response.body).not_to include("无财产保全案件")
      end
    end
    
    context "when sorting by property_preservation_deadline" do
      it "sorts cases by deadline from nearest to farthest (ASC)" do
        get '/cases', params: { 
          has_property_preservation: 'active',
          sort_by: 'property_preservation_deadline'
        }
        
        expect(response).to have_http_status(:success)
        
        # 验证返回的案件按照到期时间从近到远排序
        body = response.body
        
        # 提取案件名称在HTML中的位置
        pos_7days = body.index("有效财产保全案件（7天后到期）")
        pos_30days = body.index("有效财产保全案件（30天后到期）")
        pos_90days = body.index("有效财产保全案件（90天后到期）")
        
        # 确保所有案件都存在
        expect(pos_7days).not_to be_nil
        expect(pos_30days).not_to be_nil
        expect(pos_90days).not_to be_nil
        
        # 验证顺序：7天 < 30天 < 90天
        expect(pos_7days).to be < pos_30days
        expect(pos_30days).to be < pos_90days
      end
    end
  end
  
  describe "Model scope tests" do
    it "with_property_preservation scope returns cases with deadline set" do
      cases = Case.with_property_preservation
      
      expect(cases.count).to eq(4)
      expect(cases).to include(case_with_expired_pp)
      expect(cases).to include(case_with_active_pp_far)
      expect(cases).to include(case_with_active_pp_near)
      expect(cases).to include(case_with_active_pp_soon)
      expect(cases).not_to include(case_without_pp)
    end
    
    it "with_active_property_preservation scope returns only non-expired cases" do
      cases = Case.with_active_property_preservation
      
      expect(cases.count).to eq(3)
      expect(cases).to include(case_with_active_pp_far)
      expect(cases).to include(case_with_active_pp_near)
      expect(cases).to include(case_with_active_pp_soon)
      expect(cases).not_to include(case_with_expired_pp)
      expect(cases).not_to include(case_without_pp)
    end
    
    it "order_by_field with property_preservation_deadline sorts correctly" do
      cases = Case.with_active_property_preservation
                  .order_by_field('property_preservation_deadline')
      
      expect(cases.count).to eq(3)
      expect(cases.first).to eq(case_with_active_pp_soon)  # 7天后
      expect(cases.second).to eq(case_with_active_pp_near)  # 30天后
      expect(cases.third).to eq(case_with_active_pp_far)   # 90天后
    end
  end
  
  describe "Filter panel rendering" do
    it "includes property preservation filter option in cases index" do
      get '/cases'
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('财产保全')
      expect(response.body).to include('全部涉及财产保全的案件')
      expect(response.body).to include('有效财产保全案件')
    end
    
    it "includes property preservation deadline in sort options" do
      get '/cases'
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('财产保全到期时间（由近到远）')
    end
  end
end
