class AnnouncementsController < ApplicationController
  before_action :require_login
  before_action :set_announcement, only: [:mark_as_read]
  before_action :set_company, only: [:index, :enter]
  
  def index
    # 获取筛选参数
    @selected_priority = params[:priority]
    @selected_type = params[:type]
    @selected_read_status = params[:read_status]
    @search_query = params[:q]
    
    # 获取公告数据
    announcement_service = AnnouncementService.new(
      user: current_company_user,
      company_ids: [@company.id]
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
      announcement&.mark_as_read_by(current_company_user)
    end
    
    # 跳转到目标页面
    redirect_path = params[:redirect_to] || workbench_index_path
    redirect_to redirect_path, notice: "已跳转到相关内容"
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
            user: current_user_for_announcement,
            reason: params[:reason] || 'manual'
          )
          
          redirect_back fallback_location: workbench_index_path, notice: "✅ 公告已消除"
        else
          redirect_back fallback_location: workbench_index_path, alert: "操作失败：找不到相关对象"
        end
      rescue => e
        redirect_back fallback_location: workbench_index_path, alert: "操作失败：#{e.message}"
      end
    else
      redirect_back fallback_location: workbench_index_path, alert: "操作失败：参数错误"
    end
  end
  
  # 恢复公告（取消消除）
  def restore
    announcement_type = params[:announcement_type]
    related_type = params[:related_type]
    related_id = params[:related_id]
    
    if related_type.present? && related_id.present?
      begin
        related_object = related_type.constantize.find_by(id: related_id)
        
        if related_object
          AnnouncementDismissal.restore!(
            announcement_type: announcement_type,
            related: related_object,
            user: current_user_for_announcement
          )
          
          redirect_back fallback_location: workbench_index_path, notice: "✅ 公告已恢复"
        else
          redirect_back fallback_location: workbench_index_path, alert: "操作失败：找不到相关对象"
        end
      rescue => e
        redirect_back fallback_location: workbench_index_path, alert: "操作失败：#{e.message}"
      end
    else
      redirect_back fallback_location: workbench_index_path, alert: "操作失败：参数错误"
    end
  end
  
  # 批量消除公告
  def dismiss_batch
    announcement_ids = params[:announcement_ids] || []
    dismissed_count = 0
    
    announcement_ids.each do |ann_id|
      # 解析公告 ID（如 "contract_review_123"）
      parts = ann_id.split('_')
      next if parts.length < 2
      
      related_id = parts.last.to_i
      announcement_type = parts[0..-2].join('_')
      
      # 根据公告类型确定模型
      related_class = case announcement_type
      when 'hearing', 'judgement_collection' then Case
      when 'contract_review', 'contract_expiry', 'reconciliation_overdue' then Contract
      else next
      end
      
      related_object = related_class.find_by(id: related_id)
      next unless related_object
      
      begin
        AnnouncementDismissal.dismiss!(
          announcement_type: announcement_type,
          related: related_object,
          user: current_user_for_announcement,
          reason: 'batch_manual'
        )
        dismissed_count += 1
      rescue
        # 忽略错误，继续处理下一个
      end
    end
    
    redirect_back fallback_location: workbench_index_path, notice: "✅ 已消除 #{dismissed_count} 条公告"
  end
  
  # 标记公告为已读（仅手动公告支持）
  def mark_as_read
    if @announcement && current_user_for_announcement
      @announcement.mark_as_read_by(current_user_for_announcement)
      render turbo_stream: turbo_stream.replace(
        "announcement_#{@announcement.id}",
        partial: 'announcements/read_status',
        locals: { announcement: @announcement }
      )
    else
      render turbo_stream: turbo_stream.append('flash', partial: 'shared/flash', locals: { type: 'alert', message: '操作失败' }), status: :unprocessable_entity
    end
  end
  
  private
  
  def set_company
    @company = current_company_user.company
  end
  
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
  
  def set_announcement
    @announcement = Announcement.find_by(id: params[:id])
  end
  
  def require_login
    unless current_company_user || current_lawyer
      redirect_to root_path, alert: '请先登录'
    end
  end
  
  def current_user_for_announcement
    current_company_user || current_lawyer
  end
end