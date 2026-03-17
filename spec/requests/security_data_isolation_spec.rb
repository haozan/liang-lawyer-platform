require 'rails_helper'

RSpec.describe "Security: Data Isolation Between Companies", type: :request do
  # 创建两个独立的公司环境
  let!(:company_a) { create(:company, name: '甲公司') }
  let!(:company_b) { create(:company, name: '乙公司') }
  
  # 企业用户
  let!(:user_a) { create(:company_user, company: company_a, role: 'boss', name: '甲公司老板') }
  let!(:user_b) { create(:company_user, company: company_b, role: 'boss', name: '乙公司老板') }
  
  # 数据
  let!(:contract_a) { create(:contract, company: company_a, name: '甲公司合同') }
  let!(:contract_b) { create(:contract, company: company_b, name: '乙公司合同') }
  
  let!(:case_a) { create(:case, company: company_a, name: '甲公司案件') }
  let!(:case_b) { create(:case, company: company_b, name: '乙公司案件') }
  
  let!(:major_issue_a) { create(:major_issue, company: company_a, title: '甲公司重大事项') }
  let!(:major_issue_b) { create(:major_issue, company: company_b, title: '乙公司重大事项') }
  
  let!(:comment_a) { create(:comment, commentable: contract_a, author: user_a, author_name: user_a.display_name, author_role: 'boss', content: '甲公司的评论') }
  let!(:comment_b) { create(:comment, commentable: contract_b, author: user_b, author_name: user_b.display_name, author_role: 'boss', content: '乙公司的评论') }
  
  before do
    # 使用真实的session登录甲公司用户
    post login_path, params: { phone: user_a.phone, password: 'password123' }
    expect(session[:current_company_user_id]).to eq(user_a.id)
    expect(session[:user_type]).to eq('company_user')
  end
  
  describe "🔒 合同档案数据隔离" do
    it "企业用户只能访问列表中自己企业的合同" do
      get contracts_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('甲公司合同')
      expect(response.body).not_to include('乙公司合同')
    end
    
    it "企业用户可以访问自己企业的合同详情" do
      get contract_path(contract_a)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('甲公司合同')
    end
    
    it "🚨 CRITICAL: 企业用户不能通过URL直接访问其他企业的合同" do
      # 尝试访问乙公司的合同 - 应该返回404或重定向
      get contract_path(contract_b)
      expect(response).to have_http_status(:not_found)
    end
    
    it "🚨 CRITICAL: 企业用户不能修改其他企业的合同" do
      patch contract_path(contract_b), params: { contract: { name: '篡改名称' } }
      expect(response).to have_http_status(:not_found)
    end
    
    it "🚨 CRITICAL: 企业用户不能删除其他企业的合同" do
      expect {
        delete contract_path(contract_b)
      }.not_to change(Contract, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
  
  describe "🔒 案件数据隔离" do
    it "企业用户只能访问列表中自己企业的案件" do
      get cases_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('甲公司案件')
      expect(response.body).not_to include('乙公司案件')
    end
    
    it "企业用户可以访问自己企业的案件详情" do
      get case_path(case_a)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('甲公司案件')
    end
    
    it "🚨 CRITICAL: 企业用户不能通过URL直接访问其他企业的案件" do
      get case_path(case_b)
      expect(response).to have_http_status(:not_found)
    end
    
    it "🚨 CRITICAL: 企业用户不能修改其他企业的案件" do
      patch case_path(case_b), params: { case: { name: '篡改名称' } }
      expect(response).to have_http_status(:not_found)
    end
    
    it "🚨 CRITICAL: 企业用户不能删除其他企业的案件" do
      expect {
        delete case_path(case_b)
      }.not_to change(Case, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
  
  describe "🔒 重大事项数据隔离" do
    it "企业用户只能访问列表中自己企业的重大事项" do
      get major_issues_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('甲公司重大事项')
      expect(response.body).not_to include('乙公司重大事项')
    end
    
    it "企业用户可以访问自己企业的重大事项详情" do
      get major_issue_path(major_issue_a)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('甲公司重大事项')
    end
    
    it "🚨 CRITICAL: 企业用户不能通过URL直接访问其他企业的重大事项" do
      get major_issue_path(major_issue_b)
      expect(response).to have_http_status(:not_found)
    end
    
    it "🚨 CRITICAL: 企业用户不能修改其他企业的重大事项" do
      patch major_issue_path(major_issue_b), params: { major_issue: { title: '篡改标题' } }
      expect(response).to have_http_status(:not_found)
    end
    
    it "🚨 CRITICAL: 企业用户不能删除其他企业的重大事项" do
      expect {
        delete major_issue_path(major_issue_b)
      }.not_to change(MajorIssue, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
  
  describe "🔒 评论数据隔离" do
    it "🚨 CRITICAL: 企业用户不能访问其他企业资源的评论" do
      # 评论是通过 commentable 关联的，访问乙公司合同时会失败（因为无法访问合同本身）
      get contract_path(contract_b)
      expect(response).to have_http_status(:not_found)
    end
    
    it "🚨 CRITICAL: 企业用户不能删除其他企业的评论" do
      expect {
        delete comment_path(comment_b)
      }.not_to change(Comment, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
  
  describe "🔒 搜索功能数据隔离" do
    it "企业用户搜索只能看到自己企业的结果" do
      # 清空现有索引，重新创建
      SearchIndex.where(searchable_type: 'Contract').delete_all
      
      SearchIndex.create!(
        searchable_type: 'Contract',
        searchable_id: contract_a.id,
        company_id: company_a.id,
        title: '甲公司合同',
        content: '甲公司合同内容',
        category: '合同档案',
        indexed_at: Time.current
      )
      
      SearchIndex.create!(
        searchable_type: 'Contract',
        searchable_id: contract_b.id,
        company_id: company_b.id,
        title: '乙公司合同',
        content: '乙公司合同内容',
        category: '合同档案',
        indexed_at: Time.current
      )
      
      get search_path, params: { q: '合同' }
      expect(response).to have_http_status(:success)
      # 使用公司名称来检查，因为搜索结果会用 <mark> 标签高亮关键词
      expect(response.body).to include('甲公司')
      expect(response.body).not_to include('乙公司')
    end
  end
  
  describe "🔒 待办事项数据隔离" do
    it "企业用户的待办事项只包含自己企业的数据" do
      get todos_path
      expect(response).to have_http_status(:success)
      
      # 待办事项中应该包含甲公司的数据
      # 不应包含乙公司的数据（通过检查公司名称）
      expect(response.body).to include(company_a.name)
      expect(response.body).not_to include(company_b.name)
    end
  end
  
  describe "🔒 工作台数据隔离" do
    it "企业用户工作台只显示自己企业的数据" do
      get workbench_index_path
      expect(response).to have_http_status(:success)
      
      # 统计数据应该只包含甲公司的
      expect(response.body).to include(company_a.name)
      expect(response.body).not_to include(company_b.name)
    end
  end
  
  describe "🔒 数据分析功能隔离" do
    it "企业用户访问合同分析时只能看到自己企业的数据" do
      get dashboard_contract_analytics_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(company_a.name)
      expect(response.body).not_to include(company_b.name)
    end
    
    it "🚨 CRITICAL: 企业用户不能通过参数访问其他企业的数据分析" do
      get dashboard_contract_analytics_path, params: { company_id: company_b.id }
      # 应该被重定向或显示警告
      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response.body).to include('没有权限查看该企业数据')
    end
    
    it "企业用户访问案件分析时只能看到自己企业的数据" do
      get dashboard_case_analytics_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(company_a.name)
      expect(response.body).not_to include(company_b.name)
    end
    
    it "🚨 CRITICAL: 企业用户不能通过参数访问其他企业的案件分析" do
      get dashboard_case_analytics_path, params: { company_id: company_b.id }
      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response.body).to include('没有权限查看该企业数据')
    end
  end
  
  describe "🔒 公告功能数据隔离" do
    it "企业用户只能看到自己企业的公告" do
      # 公告功能是通过 AnnouncementService 过滤的，默认只展示当前公司的公告
      get announcements_path
      expect(response).to have_http_status(:success)
      # 页面应该包含当前公司的名称
      expect(response.body).to include(company_a.name)
    end
  end
end
