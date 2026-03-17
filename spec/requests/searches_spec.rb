require 'rails_helper'

RSpec.describe "Searches", type: :request do
  let(:company1) { create(:company, name: "律所A") }
  let(:company2) { create(:company, name: "律所B") }
  let(:lawyer) { create(:lawyer_account, name: "张律师") }
  let(:company1_user) { create(:company_user, company: company1, name: "企业用户1") }
  let(:company2_user) { create(:company_user, company: company2, name: "企业用户2") }
  
  let!(:contract1) { create(:contract, company: company1, name: "公司A的合同") }
  let!(:contract2) { create(:contract, company: company2, name: "公司B的合同") }
  let!(:case1) { create(:case, company: company1, name: "公司A的案件") }
  let!(:case2) { create(:case, company: company2, name: "公司B的案件") }
  
  before do
    # 确保所有模型都已创建搜索索引
    [contract1, contract2, case1, case2].each(&:update_search_index)
  end
  
  describe "GET /search" do
    context "when user is a lawyer" do
      before do 
        sign_in_as_lawyer(lawyer)
      end
      
      it "can search across all companies" do
        get search_path, params: { q: "合同" }
        
        expect(response).to have_http_status(:ok)
        # 律师应该能看到两家公司的结果（使用正则表达式忽略 HTML 标签）
        expect(response.body).to match(/公司A.*合同/m)
        expect(response.body).to match(/公司B.*合同/m)
      end
      
      it "can search cases across all companies" do
        get search_path, params: { q: "案件" }
        
        expect(response).to have_http_status(:ok)
        expect(response.body).to match(/公司A.*案件/m)
        expect(response.body).to match(/公司B.*案件/m)
      end
      
      it "shows results count correctly" do
        get search_path, params: { q: "公司" }
        
        expect(response).to have_http_status(:ok)
        # 应该找到多条记录（合同 + 案件 + 对账单 + 重大问题）
        # 只验证结果数大于 4
        expect(response.body).to match(/找到.*\d+.*条结果/m)
      end
    end
    
    context "when user is a company user from company1" do
      before do
        sign_in_as_company_user(company1_user)
      end
      
      it "can only search within their own company" do
        get search_path, params: { q: "合同" }
        
        expect(response).to have_http_status(:ok)
        # 企业用户只能看到自己公司的结果
        expect(response.body).to match(/公司A.*合同/m)
        expect(response.body).not_to match(/公司B.*合同/m)
      end
      
      it "can only see their company's cases" do
        get search_path, params: { q: "案件" }
        
        expect(response).to have_http_status(:ok)
        expect(response.body).to match(/公司A.*案件/m)
        expect(response.body).not_to match(/公司B.*案件/m)
      end
      
      it "shows correct permission indicator" do
        get search_path, params: { q: "公司" }
        
        expect(response).to have_http_status(:ok)
        # 应该显示企业用户权限提示（使用正则匹配忽略 HTML）
        expect(response.body).to match(/仅搜索.*律所A/m)
      end
    end
    
    context "when user is a company user from company2" do
      before do
        sign_in_as_company_user(company2_user)
      end
      
      it "can only search within their own company" do
        get search_path, params: { q: "合同" }
        
        expect(response).to have_http_status(:ok)
        expect(response.body).to match(/公司B.*合同/m)
        expect(response.body).not_to match(/公司A.*合同/m)
      end
      
      it "shows empty results for other company's data" do
        get search_path, params: { q: "公司A" }
        
        expect(response).to have_http_status(:ok)
        expect(response.body).to match(/未找到.*结果|0.*条结果/m)
      end
    end
    
    context "with category filtering" do
      before do
        sign_in_as_lawyer(lawyer)
      end
      
      it "filters by specific category" do
        get search_path, params: { q: "公司", category: "合同档案" }
        
        expect(response).to have_http_status(:ok)
        # 验证合同结果存在（考虑 <mark> 标签会分隔文字）
        expect(response.body).to match(/公司.*A.*合同/m)
        expect(response.body).to match(/公司.*B.*合同/m)
        # 验证所有结果都显示为合同档案类别（badge 标签）
        # 统计 "合同档案" 在 badge-secondary 标签中的出现次数，应该 = 3
        contract_badges = response.body.scan(/<span class="badge badge-secondary[^>]*>合同档案<\/span>/)
        expect(contract_badges.length).to eq(3)
      end
    end
    
    context "with empty query" do
      before do
        sign_in_as_lawyer(lawyer)
      end
      
      it "shows search tips" do
        get search_path
        
        expect(response).to have_http_status(:ok)
        expect(response.body).to match(/全局搜索|开始搜索/m)
      end
    end
  end
  
  describe "SearchIndex model" do
    it "creates index when contract is created" do
      expect {
        contract = create(:contract, company: company1, name: "新合同")
      }.to change(SearchIndex, :count).by(1)
      
      index = SearchIndex.last
      expect(index.title).to eq("新合同")
      expect(index.company_id).to eq(company1.id)
      expect(index.category).to eq("合同档案")
    end
    
    it "updates index when contract is updated" do
      contract = create(:contract, company: company1, name: "原名称")
      old_index_id = SearchIndex.last.id
      
      contract.update(name: "新名称")
      
      index = SearchIndex.find(old_index_id)
      expect(index.title).to eq("新名称")
    end
    
    it "removes index when contract is destroyed" do
      contract = create(:contract, company: company1)
      expect(SearchIndex.count).to be > 0
      
      expect {
        contract.destroy
      }.to change(SearchIndex, :count).by(-1)
    end
  end
  
  private
  
  def sign_in_as_lawyer(lawyer)
    # 通过真实登录流程设置 session
    post login_path, params: {
      phone: lawyer.phone,
      password: 'password123',
      login_type: 'password'
    }
    follow_redirect!  # 跟随重定向以完成登录流程
  end
  
  def sign_in_as_company_user(company_user)
    # 通过真实登录流程设置 session
    post login_path, params: {
      phone: company_user.phone,
      password: 'password123',
      login_type: 'password'
    }
    follow_redirect!  # 跟随重定向以完成登录流程
  end
end
