require 'rails_helper'

RSpec.describe "Company Filtering", type: :request do
  let(:lawyer) { create(:lawyer_account) }
  let(:company_a) { create(:company, name: "公司A") }
  let(:company_b) { create(:company, name: "公司B") }
  let!(:contract_a) { create(:contract, company: company_a, name: "公司A的合同") }
  let!(:contract_b) { create(:contract, company: company_b, name: "公司B的合同") }

  def sign_in_lawyer(lawyer_account)
    post login_path, params: { 
      phone: lawyer_account.phone, 
      password: 'password123',
      user_type: 'lawyer'
    }
  end

  describe "律师工作台快捷入口的公司过滤" do
    before { sign_in_lawyer(lawyer) }

    context "点击合同管理快捷入口" do
      it "传递 company_id 参数时，应该设置 session 并显示对应公司的合同" do
        get contracts_path(company_id: company_a.id)
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include("公司A的合同")
        expect(response.body).not_to include("公司B的合同")
        
        # 验证 session 已设置
        expect(session[:viewing_company_id]).to eq(company_a.id)
      end

      it "切换到另一个公司时，session 和显示内容应该正确更新" do
        # 先访问公司A
        get contracts_path(company_id: company_a.id)
        expect(response.body).to include("公司A的合同")
        expect(session[:viewing_company_id]).to eq(company_a.id)
        
        # 切换到公司B
        get contracts_path(company_id: company_b.id)
        expect(response.body).to include("公司B的合同")
        expect(response.body).not_to include("公司A的合同")
        expect(session[:viewing_company_id]).to eq(company_b.id)
      end

      it "设置 session 后，不传 company_id 参数应该继续显示该公司的合同" do
        # 先设置 session
        get contracts_path(company_id: company_a.id)
        expect(session[:viewing_company_id]).to eq(company_a.id)
        
        # 不传 company_id 参数再次访问
        get contracts_path
        expect(response.body).to include("公司A的合同")
        expect(session[:viewing_company_id]).to eq(company_a.id)
      end
    end

    context "点击案件管理快捷入口" do
      let!(:case_a) { create(:case, company: company_a, name: "公司A的案件") }
      let!(:case_b) { create(:case, company: company_b, name: "公司B的案件") }

      it "传递 company_id 参数时，应该设置 session 并显示对应公司的案件" do
        get cases_path(company_id: company_a.id)
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include("公司A的案件")
        expect(response.body).not_to include("公司B的案件")
        expect(session[:viewing_company_id]).to eq(company_a.id)
      end
    end

    context "点击重大事项快捷入口" do
      let!(:issue_a) { create(:major_issue, company: company_a, title: "公司A的重大事项") }
      let!(:issue_b) { create(:major_issue, company: company_b, title: "公司B的重大事项") }

      it "传递 company_id 参数时，应该设置 session 并显示对应公司的重大事项" do
        get major_issues_path(company_id: company_a.id)
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include("公司A的重大事项")
        expect(response.body).not_to include("公司B的重大事项")
        expect(session[:viewing_company_id]).to eq(company_a.id)
      end
    end

    context "选择全部企业" do
      let!(:case_a) { create(:case, company: company_a, name: "公司A的案件") }
      let!(:case_b) { create(:case, company: company_b, name: "公司B的案件") }

      it "传递 company_id='all' 时，应该显示所有企业的案件" do
        get cases_path(company_id: 'all')
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include("公司A的案件")
        expect(response.body).to include("公司B的案件")
        expect(session[:viewing_company_id]).to be_nil
      end

      it "从单个企业切换到全部企业后，应该显示所有案件" do
        # 先访问公司A
        get cases_path(company_id: company_a.id)
        expect(response.body).to include("公司A的案件")
        expect(response.body).not_to include("公司B的案件")
        
        # 切换到全部企业
        get cases_path(company_id: 'all')
        expect(response.body).to include("公司A的案件")
        expect(response.body).to include("公司B的案件")
        expect(session[:viewing_company_id]).to be_nil
      end
    end
end
end
