class Admin::DashboardController < Admin::BaseController
  def index
    @stats = {
      companies: Company.count,
      lawyer_accounts: LawyerAccount.count,
      company_users: CompanyUser.count,
      cases: Case.count,
      contracts: Contract.count
    }
  end
end
