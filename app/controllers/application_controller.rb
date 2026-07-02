class ApplicationController < ActionController::Base
  allow_browser versions: { chrome: 80, firefox: 75, safari: 13, edge: 80, opera: 67 }

  include FriendlyErrorHandlingConcern
  include DevelopmentCsrfBypassConcern
  include TurboCompatibleRenderConcern

  before_action :require_authentication
  before_action :set_current_lawyer_account

  helper_method :current_lawyer, :current_company_user, :current_user,
                :lawyer?, :company_user?, :viewing_company, :can_edit?,
                :current_membership

  private

  def current_lawyer
    @current_lawyer ||= LawyerAccount.find_by(id: session[:current_lawyer_id]) if session[:user_type] == 'lawyer'
  end

  def current_company_user
    @current_company_user ||= CompanyUser.find_by(id: session[:current_company_user_id]) if session[:user_type] == 'company_user'
  end

  def current_user
    current_lawyer || current_company_user
  end

  # 兼容旧代码
  alias_method :current_lawyer_account, :current_lawyer

  def set_current_lawyer_account
    Current.lawyer_account = current_lawyer
  end

  def lawyer?
    current_lawyer.present?
  end

  def company_user?
    current_company_user.present?
  end

  # 🔒 核心权限：企业用户只能看不能操作
  def can_edit?
    lawyer?
  end

  # 企业用户当前选择的企业（数据隔离核心）
  def viewing_company
    return nil unless company_user?
    @viewing_company ||= begin
      cid = session[:viewing_company_id]
      current_company_user.companies.find_by(id: cid) if cid
    end
  end

  # 企业用户在当前企业的 membership（视图兼容）
  def current_membership
    return nil unless company_user? && viewing_company
    @current_membership ||= current_company_user.company_memberships.find_by(company: viewing_company)
  end

  def require_authentication
    return if current_user
    redirect_to login_path, alert: '请先登录'
  end

  def require_lawyer
    return if lawyer?
    redirect_to root_path, alert: '无权访问'
  end

  # 🔒 写操作统一拦截：企业用户只读
  def require_edit_permission
    return if can_edit?
    redirect_to root_path, alert: '您只有查看权限，无法执行此操作'
  end
end
