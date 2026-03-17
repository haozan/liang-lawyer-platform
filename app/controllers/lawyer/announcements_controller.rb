class Lawyer::AnnouncementsController < ApplicationController
  before_action :require_lawyer

  def index
    # 获取筛选参数
    @selected_company_id = params[:company_id]
    @selected_priority = params[:priority]
    @selected_type = params[:type]
    @selected_read_status = params[:read_status]
    @search_query = params[:q]
    
    # 获取所有企业列表（用于筛选器）
    @companies = Company.ordered
    
    # 确定要查询的企业范围
    announcement_company_ids = if @selected_company_id.present?
      [@selected_company_id.to_i]
    else
      @companies.pluck(:id)
    end
    
    # 获取公告数据
    announcement_service = AnnouncementService.new(
      user: current_lawyer,
      company_ids: announcement_company_ids
    )
    announcement_data = announcement_service.call
    all_announcements = announcement_data[:combined_announcements]
    
    # 应用筛选条件
    @announcements = filter_announcements(all_announcements)
    
    # 分页（Kaminari）
    @announcements = Kaminari.paginate_array(@announcements).page(params[:page]).per(20)
    
    # 统计数据
    @total_count = all_announcements.count
    @unread_count = all_announcements.count { |a| a[:type] == 'manual' && !a[:read] }
    @urgent_count = all_announcements.count { |a| a[:priority] == 'urgent' }
    @important_count = all_announcements.count { |a| a[:priority] == 'important' }
  end
  
  # 标记公告为已读并跳转
  def enter
    announcement_id = params[:announcement_id]
    related_type = params[:related_type]
    related_id = params[:related_id]
    
    # 如果是手动公告，标记为已读
    if announcement_id&.start_with?('manual_')
      db_announcement_id = announcement_id.gsub('manual_', '').to_i
      announcement = Announcement.find_by(id: db_announcement_id)
      announcement&.mark_as_read_by(current_lawyer)
    end
    
    # 自动设置 viewing_company_id
    if related_type.present? && related_id.present?
      related_record = related_type.constantize.find_by(id: related_id)
      if related_record&.respond_to?(:company_id)
        session[:viewing_company_id] = related_record.company_id
      end
    end
    
    # 跳转到目标页面
    redirect_path = params[:redirect_to] || lawyer_companies_path
    redirect_to redirect_path, notice: "已自动切换到对应企业"
  end
  
  # 消除公告（用户手动忽略）
  def dismiss
    announcement_type = params[:announcement_type]
    related_type = params[:related_type]
    related_id = params[:related_id]
    
    if related_type.present? && related_id.present?
      begin
        related_object = related_type.constantize.find_by(id: related_id)
        
        if related_object
          AnnouncementDismissal.dismiss!(
            announcement_type: announcement_type,
            related: related_object,
            user: current_lawyer,
            reason: params[:reason] || 'manual'
          )
          
          redirect_back fallback_location: lawyer_companies_path, notice: "✅ 公告已消除"
        else
          redirect_back fallback_location: lawyer_companies_path, alert: "操作失败：找不到相关对象"
        end
      rescue => e
        redirect_back fallback_location: lawyer_companies_path, alert: "操作失败：#{e.message}"
      end
    else
      redirect_back fallback_location: lawyer_companies_path, alert: "操作失败：参数错误"
    end
  end

  private

  def filter_announcements(announcements)
    filtered = announcements
    
    # 按优先级筛选
    if @selected_priority.present?
      filtered = filtered.select { |a| a[:priority] == @selected_priority }
    end
    
    # 按类型筛选
    if @selected_type.present?
      filtered = filtered.select { |a| a[:announcement_type] == @selected_type }
    end
    
    # 按已读/未读筛选（仅手动公告）
    if @selected_read_status.present?
      filtered = filtered.select do |a|
        if @selected_read_status == 'unread'
          a[:type] == 'manual' && !a[:read]
        elsif @selected_read_status == 'read'
          a[:type] == 'manual' && a[:read]
        else
          true
        end
      end
    end
    
    # 搜索功能
    if @search_query.present?
      query_downcase = @search_query.downcase
      filtered = filtered.select do |a|
        a[:title].downcase.include?(query_downcase) ||
        (a[:content].present? && a[:content].downcase.include?(query_downcase))
      end
    end
    
    filtered
  end
end
