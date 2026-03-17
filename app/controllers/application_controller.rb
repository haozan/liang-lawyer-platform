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
  before_action :set_current_lawyer_account
  helper_method :current_lawyer, :current_company_user, :current_user, :current_lawyer_account, :lawyer?, :company_user?, :viewing_company, :lawyer_announcement_count

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
  
  # 别名方法：current_lawyer_account = current_lawyer
  # 用于团队权限系统
  def current_lawyer_account
    current_lawyer
  end
  
  # 设置 Current.lawyer_account，供模型层使用
  def set_current_lawyer_account
    Current.lawyer_account = current_lawyer
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

  def require_boss_role
    return if company_user? && current_company_user.role == 'boss'
    redirect_to root_path, alert: '无权访问'
  end
  
  # 获取律师的公告数量（用于导航栏徽章）
  def lawyer_announcement_count
    return 0 unless lawyer?
    
    # 使用 Rails.cache 缓存公告数量，避免频繁查询
    Rails.cache.fetch("lawyer_#{current_lawyer.id}_announcement_count", expires_in: 5.minutes) do
      company_ids = Company.pluck(:id)
      announcement_service = AnnouncementService.new(
        user: current_lawyer,
        company_ids: company_ids
      )
      announcement_service.call[:combined_announcements].count
    end
  rescue
    0
  end

end
