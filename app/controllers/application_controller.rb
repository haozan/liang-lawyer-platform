class ApplicationController < ActionController::Base
  # Allow browsers with broader compatibility
  allow_browser versions: {
    chrome: 80,
    firefox: 75,
    safari: 13,
    edge: 80,
    opera: 67
  }

  include FriendlyErrorHandlingConcern
  include DevelopmentCsrfBypassConcern
  include TurboCompatibleRenderConcern

  before_action :require_authentication
  helper_method :current_lawyer, :current_company_user, :current_user, :lawyer?, :company_user?, :viewing_company

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

  def lawyer?
    current_lawyer.present?
  end

  def company_user?
    current_company_user.present?
  end

  def viewing_company
    return nil unless lawyer?
    @viewing_company ||= Company.find_by(id: session[:viewing_company_id]) if session[:viewing_company_id]
  end

  def require_authentication
    return if current_user
    redirect_to login_path, alert: '请先登录'
  end

  def require_lawyer
    return if lawyer?
    redirect_to root_path, alert: '无权访问'
  end

  def require_company_user
    return if company_user?
    redirect_to root_path, alert: '无权访问'
  end

  def require_hr_role
    return if company_user? && current_company_user.role == 'hr'
    redirect_to root_path, alert: '无权访问'
  end

  def require_contract_role
    return if company_user? && current_company_user.role == 'contract'
    redirect_to root_path, alert: '无权访问'
  end

  def require_boss_role
    return if company_user? && current_company_user.role == 'boss'
    redirect_to root_path, alert: '无权访问'
  end

end
