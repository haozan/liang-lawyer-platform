class WorkbenchController < ApplicationController
  before_action :require_company_user
  before_action :set_company
  
  def index
    # 获取待办数据 - 使用UnifiedTodoService
    todo_service = UnifiedTodoService.new(company: @company, user_type: :company)
    todo_data = todo_service.call
    
    @stats = todo_data[:stats]
    @urgent_items = todo_data[:urgent_items]
    @pending_contracts = todo_data[:pending_contracts]
    @pending_cases = todo_data[:pending_cases]
    @pending_major_issues = todo_data[:pending_major_issues]
    
    # 获取届满提醒数据
    expiry_service = LawyerExpiryService.new(company_id: @company.id)
    expiry_data = expiry_service.call
    
    @expiring_contracts = expiry_data[:expiring_contracts]
    @upcoming_hearings = expiry_data[:upcoming_hearings]
    @pending_judgement_collections = expiry_data[:pending_judgement_collections]
    @pending_archives = expiry_data[:pending_archives]
    @expiry_total_count = expiry_data[:total_count]
    
    # 使用 AnnouncementService 获取公告（替代旧的提醒逻辑）
    announcement_service = AnnouncementService.new(
      user: current_company_user,
      company_ids: [@company.id]
    )
    announcement_data = announcement_service.call
    @announcements = announcement_data[:combined_announcements]
    @grouped_announcements = announcement_data[:grouped_announcements]
    @announcement_stats = announcement_data[:stats]
  end
  
  private
  
  def set_company
    @company = current_company_user.company
  end
  
  def require_company_user
    unless current_company_user
      redirect_to root_path, alert: '请先登录'
    end
  end
end
