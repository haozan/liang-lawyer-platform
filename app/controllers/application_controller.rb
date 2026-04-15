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
  helper_method :current_lawyer, :current_company_user, :current_user, :current_lawyer_account,
                :lawyer?, :company_user?, :viewing_company, :current_membership,
                :lawyer_announcement_count

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

  # 别名：兼容旧代码 current_lawyer_account
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

  # 企业用户当前选择的企业
  def viewing_company
    return nil unless company_user?
    @viewing_company ||= begin
      cid = session[:viewing_company_id]
      if cid
        # 确认该企业确实是用户所属的
        current_company_user.companies.find_by(id: cid)
      end
    end
  end

  # 当前企业用户在 viewing_company 中的 membership
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

  def require_company_user
    return if company_user?
    redirect_to root_path, alert: '无权访问'
  end

  def require_boss_role
    return if company_user? && current_membership&.boss?
    redirect_to root_path, alert: '无权访问'
  end

  # 获取律师的公告数量（用于导航栏徽章）
  def lawyer_announcement_count
    return 0 unless lawyer?

    AnnouncementService.new(user: current_lawyer).call[:combined_announcements].count
  rescue ActiveRecord::StatementInvalid, PG::Error => e
    Rails.logger.error("[AnnouncementService] DB error in lawyer_announcement_count: #{e.message}")
    0
  rescue StandardError => e
    Rails.logger.warn("[AnnouncementService] Unexpected error in lawyer_announcement_count: #{e.class} - #{e.message}")
    0
  end
end
