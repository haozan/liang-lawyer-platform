class MajorIssuesController < ApplicationController
  include CompanyResolvable
  
  before_action :require_authentication
  before_action :set_company, except: [:resolve, :archive, :reopen, :update_conclusion, :follow, :unfollow]
  before_action :set_major_issue, only: [:show, :edit, :update, :destroy, :request_deletion, :confirm_deletion, :delete_directly, :mark_as_reviewed, :export_archive, :resolve, :archive, :reopen, :update_conclusion, :follow, :unfollow, :create_todo_item, :complete_todo_item, :delete_todo_item]

  def index
    # 获取当前用户
    current_actor = current_lawyer || current_company_user
    
    # 基础查询（律师选了企业时与企业员工视角一致）
    if lawyer? && @company
      @major_issues = @company.major_issues.not_deleted
    elsif lawyer?
      @major_issues = MajorIssue.accessible_by(current_lawyer_account).not_deleted
    elsif @company
      @major_issues = @company.major_issues.not_deleted
    else
      @major_issues = MajorIssue.not_deleted
    end
    
    # 应用筛选条件
    if params[:filter].present?
      filter_params = params[:filter]
      
      # 状态筛选
      if filter_params[:status].present?
        @major_issues = @major_issues.where(status: filter_params[:status])
      end
      
      # 优先级筛选
      if filter_params[:priority].present?
        @major_issues = @major_issues.where(priority: filter_params[:priority])
      end
      
      # 事项类型筛选
      if filter_params[:issue_type].present?
        @major_issues = @major_issues.where(issue_type: filter_params[:issue_type])
      end
      
      # 律师筛选
      if filter_params[:mentioned_lawyer_id].present?
        @major_issues = @major_issues.where(mentioned_lawyer_id: filter_params[:mentioned_lawyer_id])
      end
      
      # 答复状态筛选
      if filter_params[:reviewed_status].present?
        if filter_params[:reviewed_status] == 'reviewed'
          @major_issues = @major_issues.where(reviewed_by_lawyer: true)
        elsif filter_params[:reviewed_status] == 'pending'
          @major_issues = @major_issues.where(reviewed_by_lawyer: false)
        end
      end
      
      # 迟延筛选
      if filter_params[:overdue] == 'true'
        @major_issues = @major_issues.where('processing_days > 7').where.not(status: 'resolved')
      end
      
      # 关注的事项
      if filter_params[:followed] == 'true' && current_actor
        @major_issues = @major_issues.joins(:followers)
          .where(major_issue_followers: { user_type: current_actor.class.name, user_id: current_actor.id })
      end
      
      # 日期范围筛选
      if filter_params[:created_from].present?
        @major_issues = @major_issues.where('created_at >= ?', filter_params[:created_from])
      end
      
      if filter_params[:created_to].present?
        @major_issues = @major_issues.where('created_at <= ?', filter_params[:created_to].to_date.end_of_day)
      end
      
      # 关联模块筛选
      if filter_params[:related_record_type].present?
        @major_issues = @major_issues.where(related_record_type: filter_params[:related_record_type])
      end
    end
    
    # 应用搜索关键词
    if params[:q].present?
      search_term = "%#{params[:q]}%"
      @major_issues = @major_issues.where(
        'title LIKE ? OR description LIKE ? OR issue_type LIKE ?',
        search_term, search_term, search_term
      )
    end
    
    # 排序
    sort_by = params[:sort_by] || 'created_at'
    sort_direction = params[:sort_direction] || 'desc'
    
    if ['created_at', 'processing_days', 'priority'].include?(sort_by)
      @major_issues = @major_issues.order("#{sort_by} #{sort_direction}")
    else
      @major_issues = @major_issues.ordered
    end
    
    # 分页
    @major_issues = @major_issues.includes(:company, :mentioned_lawyer).page(params[:page])
    
    # 统计数据（律师选了企业时与企业员工视角一致）
    stats_scope = if lawyer? && @company
      @company.major_issues.not_deleted
    elsif lawyer?
      MajorIssue.accessible_by(current_lawyer_account).not_deleted
    elsif @company
      @company.major_issues.not_deleted
    else
      MajorIssue.not_deleted
    end
    @all_count = stats_scope.count
    @pending_count = stats_scope.pending.count
    @discussing_count = stats_scope.discussing.count
    @resolved_count = stats_scope.resolved.count
    @urgent_count = stats_scope.where(priority: 'urgent').count
    
    # 加载用户的保存筛选条件
    if current_actor
      @saved_filters = SavedFilter.where(
        user_type: current_actor.class.name,
        user_id: current_actor.id,
        filterable_type: 'MajorIssue'
      ).order(is_default: :desc, created_at: :desc)
    end
  end

  def show
    @comments = @major_issue.comments.approved.ordered
  end

  def new
    if lawyer? && @company
      # 律师已选定企业：直接在该企业下创建
      @companies = Company.accessible_by_lawyer(current_lawyer).ordered
      @selected_company = params[:company_id].present? ? Company.find(params[:company_id]) : @company
      @major_issue = MajorIssue.new
    elsif lawyer?
      # 律师未选企业：需要选择企业
      @companies = Company.accessible_by_lawyer(current_lawyer).ordered
      @selected_company = params[:company_id].present? ? Company.find(params[:company_id]) : nil
      @major_issue = MajorIssue.new
    else
      # 企业用户只能为自己的企业创建重大事项
      @major_issue = @company.major_issues.new
    end
    @lawyers = LawyerAccount.all
  end

  def edit
    @lawyers = LawyerAccount.all
  end

  def create
    if lawyer? && @company
      # 律师已选定企业：直接在该企业下创建
      @major_issue = @company.major_issues.new(major_issue_params.except(:company_id))
    elsif lawyer?
      # 律师未选企业：必须指定 company_id
      company_id = major_issue_params[:company_id]
      if company_id.blank?
        redirect_to new_major_issue_path, alert: '请选择重大事项所属企业' and return
      end
      target_company = Company.find(company_id)
      @major_issue = target_company.major_issues.new(major_issue_params.except(:company_id))
    else
      # 企业用户只能为自己的企业创建重大事项
      @major_issue = @company.major_issues.new(major_issue_params)
    end
    
    if @major_issue.save
      redirect_to major_issue_path(@major_issue), notice: '重大事项已创建'
    else
      @lawyers = LawyerAccount.all
      if lawyer? && @company
        @selected_company = @company
      elsif lawyer?
        @companies = Company.accessible_by_lawyer(current_lawyer).ordered
        @selected_company = @major_issue.company
      end
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # 分离出附件参数，单独处理
    attachments_params = params[:major_issue][:attachments] if params[:major_issue]
    update_params = major_issue_params.except(:attachments)
    
    if @major_issue.update(update_params)
      # 如果有新附件，追加而不是替换
      if attachments_params.present?
        attachments_params.each do |attachment|
          @major_issue.attachments.attach(attachment) if attachment.present?
        end
      end
      
      redirect_to major_issue_path(@major_issue), notice: '重大事项已更新'
    else
      @lawyers = LawyerAccount.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @major_issue.destroy
    redirect_to major_issues_path, notice: '重大事项已删除'
  end

  # Soft delete methods
  def request_deletion
    if current_user.role == 'employee'
      @major_issue.request_deletion_by_employee(current_user)
      redirect_to major_issue_path(@major_issue), notice: '删除请求已提交，等待老板确认'
    else
      redirect_to major_issue_path(@major_issue), alert: '只有员工可以请求删除'
    end
  end

  def confirm_deletion
    if current_user.role == 'boss'
      @major_issue.confirm_deletion_by_boss(current_user)
      redirect_to major_issues_path, notice: '删除请求已确认'
    else
      redirect_to major_issue_path(@major_issue), alert: '只有老板可以确认删除'
    end
  end

  def delete_directly
    if current_user.role == 'boss'
      @major_issue.delete_by_boss(current_user)
      redirect_to major_issues_path, notice: '重大事项已删除'
    else
      redirect_to major_issue_path(@major_issue), alert: '只有老板可以直接删除'
    end
  end
  
  # 标记重大事项为已答复（仅律师可以操作）
  def mark_as_reviewed
    unless lawyer?
      redirect_to major_issue_path(@major_issue), alert: "无权操作" and return
    end
    
    if @major_issue.mark_as_reviewed!(current_lawyer)
      # 自动消除相关公告（系统自动）
      begin
        AnnouncementDismissal.dismiss!(
          announcement_type: 'major_issue_review',
          related: @major_issue,
          user: current_lawyer,
          reason: 'reviewed'
        )
      rescue
        # 忽略消除失败
      end
      
      redirect_back fallback_location: major_issue_path(@major_issue), notice: "✅ 重大事项已标记为已答复，相关公告已自动消除"
    else
      redirect_back fallback_location: major_issue_path(@major_issue), alert: "操作失败"
    end
  end
  
  # 标记为已解决
  def resolve
    if @major_issue.may_resolve?
      @major_issue.resolve!
      redirect_to major_issue_path(@major_issue), notice: "✅ 重大事项已标记为已解决"
    else
      redirect_to major_issue_path(@major_issue), alert: "当前状态无法标记为已解决"
    end
  end
  
  # 归档
  def archive
    if @major_issue.may_archive?
      @major_issue.archive!
      redirect_to major_issue_path(@major_issue), notice: "✅ 重大事项已归档"
    else
      redirect_to major_issue_path(@major_issue), alert: "只有已解决的事项才能归档"
    end
  end
  
  # 重新打开
  def reopen
    if @major_issue.may_reopen?
      @major_issue.reopen!
      redirect_to major_issue_path(@major_issue), notice: "✅ 重大事项已重新打开"
    else
      redirect_to major_issue_path(@major_issue), alert: "当前状态无法重新打开"
    end
  end
  
  # 更新结论
  def update_conclusion
    current_actor = current_lawyer || current_company_user
    
    if current_actor.nil?
      redirect_to major_issue_path(@major_issue), alert: "无权操作" and return
    end
    
    conclusion_content = params[:conclusion]
    
    if conclusion_content.blank?
      redirect_to major_issue_path(@major_issue), alert: "结论内容不能为空" and return
    end
    
    @major_issue.update_conclusion!(conclusion_content, current_actor)
    redirect_to major_issue_path(@major_issue), notice: "✅ 结论已更新"
  end
  
  # 关注重大事项
  def follow
    current_actor = current_lawyer || current_company_user
    
    if current_actor.nil?
      redirect_to major_issue_path(@major_issue), alert: "请先登录" and return
    end
    
    # 获取通知设置（默认全部开启）
    notify_comment = params[:notify_comment].present? ? params[:notify_comment] == 'true' : true
    notify_status = params[:notify_status].present? ? params[:notify_status] == 'true' : true
    
    @major_issue.follow!(current_actor, notify_comment: notify_comment, notify_status: notify_status)
    redirect_to major_issue_path(@major_issue), notice: "✅ 已关注该重大事项"
  end
  
  # 取消关注
  def unfollow
    current_actor = current_lawyer || current_company_user
    
    if current_actor.nil?
      redirect_to major_issue_path(@major_issue), alert: "请先登录" and return
    end
    
    @major_issue.unfollow!(current_actor)
    redirect_to major_issue_path(@major_issue), notice: "✅ 已取消关注"
  end
  
  # 导出重大事项完整档案（所有登录用户可导出）
  def export_archive
    # 生成完整重大事项档案压缩包
    require 'zip'
    require 'stringio'
    
    zip_stream = Zip::OutputStream.write_buffer do |zip|
      # 添加重大事项基本信息文本文件
      issue_info = generate_major_issue_info_text(@major_issue)
      zip.put_next_entry("重大事项信息.txt")
      zip.write issue_info
      
      # 添加事项附件
      if @major_issue.attachments.attached?
        @major_issue.attachments.each do |attachment|
          zip.put_next_entry("事项附件/#{attachment.filename}")
          zip.write attachment.download
        end
      end
      
      # 添加讨论意见（所有已审核通过的意见）
      approved_comments = @major_issue.comments.approved.ordered
      if approved_comments.any?
        approved_comments.each_with_index do |comment, index|
          comment_text = "作者：#{comment.author_name}\n时间：#{comment.created_at.strftime('%Y年%m月%d日 %H:%M')}\n内容：\n#{comment.content}"
          zip.put_next_entry("讨论意见/#{index + 1}_#{comment.author_name}_#{comment.created_at.strftime('%Y%m%d')}.txt")
          zip.write comment_text
          
          # 添加讨论意见附件
          if comment.attachments.attached?
            comment.attachments.each do |attachment|
              zip.put_next_entry("讨论意见/#{index + 1}_#{comment.author_name}_附件/#{attachment.filename}")
              zip.write attachment.download
            end
          end
        end
      end
    end
    
    zip_stream.rewind
    filename = "#{@major_issue.title}_完整档案_#{Time.current.strftime('%Y%m%d')}.zip"
    send_data zip_stream.read, filename: filename, type: 'application/zip'
  end
  
  # 创建执行任务
  def create_todo_item
    current_actor = current_lawyer || current_company_user
    
    if current_actor.nil?
      redirect_to major_issue_path(@major_issue), alert: "请先登录" and return
    end
    
    title = params[:title]
    description = params[:description]
    due_date = params[:due_date]
    assignee_type = params[:assignee_type]
    assignee_id = params[:assignee_id]
    
    if title.blank?
      redirect_to major_issue_path(@major_issue), alert: "任务标题不能为空" and return
    end
    
    todo_params = {
      title: title,
      description: description,
      due_date: due_date.present? ? Date.parse(due_date) : nil,
      status: 'pending',
      creator: current_actor
    }
    
    # 如果指定了指派人
    if assignee_type.present? && assignee_id.present?
      begin
        assignee = assignee_type.constantize.find(assignee_id)
        todo_params[:assignee] = assignee
      rescue => e
        redirect_to major_issue_path(@major_issue), alert: "指定的指派人无效" and return
      end
    end
    
    todo = @major_issue.todo_items.new(todo_params)
    
    if todo.save
      redirect_to major_issue_path(@major_issue), notice: "✅ 任务已添加"
    else
      redirect_to major_issue_path(@major_issue), alert: "添加任务失败：#{todo.errors.full_messages.join(', ')}"
    end
  end
  
  # 完成执行任务
  def complete_todo_item
    current_actor = current_lawyer || current_company_user
    
    if current_actor.nil?
      redirect_to major_issue_path(@major_issue), alert: "请先登录" and return
    end
    
    todo = @major_issue.todo_items.find_by(id: params[:todo_id])
    
    unless todo
      redirect_to major_issue_path(@major_issue), alert: "任务不存在" and return
    end
    
    if todo.status == 'completed'
      redirect_to major_issue_path(@major_issue), notice: "任务已经完成" and return
    end
    
    if todo.complete!(current_actor)
      redirect_to major_issue_path(@major_issue), notice: "✅ 任务已完成"
    else
      redirect_to major_issue_path(@major_issue), alert: "完成任务失败"
    end
  end
  
  # 删除执行任务
  def delete_todo_item
    current_actor = current_lawyer || current_company_user
    
    if current_actor.nil?
      redirect_to major_issue_path(@major_issue), alert: "请先登录" and return
    end
    
    todo = @major_issue.todo_items.find_by(id: params[:todo_id])
    
    unless todo
      redirect_to major_issue_path(@major_issue), alert: "任务不存在" and return
    end
    
    # 权限检查：只有创建者或律师可以删除任务
    unless current_lawyer || (todo.creator_type == current_actor.class.name && todo.creator_id == current_actor.id)
      redirect_to major_issue_path(@major_issue), alert: "无权删除该任务" and return
    end
    
    if todo.destroy
      redirect_to major_issue_path(@major_issue), notice: "✅ 任务已删除"
    else
      redirect_to major_issue_path(@major_issue), alert: "删除任务失败"
    end
  end

  private

  def require_authentication
    unless current_user || current_lawyer
      redirect_to login_path, alert: '请先登录'
    end
  end

  # set_company 由 CompanyResolvable concern 提供

  def set_major_issue
    if current_lawyer
      # 律师可以访问所有公司的重大事项
      @major_issue = MajorIssue.find(params[:id])
      # 更新 @company 为该重大事项所属的公司
      @company = @major_issue.company
    elsif current_company_user
      # 🔒 企业用户只能访问自己公司的重大事项
      # 使用 find 方法，如果找不到会抛出 ActiveRecord::RecordNotFound
      @company = viewing_company
      @major_issue = @company.major_issues.find(params[:id])
    else
      raise ActiveRecord::RecordNotFound, "Major issue not found or access denied"
    end
  end

  def major_issue_params
    params.require(:major_issue).permit(
      :company_id,
      :title,
      :issue_type,
      :priority,
      :status,
      :description,
      :mentioned_lawyer_id,
      :resolved_at,
      team_member_ids: [],
      attachments: []
    )
  end
  
  # 生成重大事项信息文本
  def generate_major_issue_info_text(major_issue)
    info = []
    info << "标题：#{major_issue.title}"
    info << "事项类型：#{major_issue.issue_type}"
    info << "优先级：#{major_issue.priority_display}"
    info << "状态：#{major_issue.status_display}"
    info << "所属企业：#{major_issue.company.name}"
    if major_issue.mentioned_lawyer.present?
      info << "@提及律师：#{major_issue.mentioned_lawyer.name}"
    end
    info << "律师答复状态：#{major_issue.reviewed_by_lawyer ? '已答复' : '待答复'}"
    if major_issue.reviewed_by_lawyer && major_issue.reviewed_at.present?
      info << "答复时间：#{major_issue.reviewed_at.strftime('%Y年%m月%d日 %H:%M')}"
    end
    if major_issue.resolved_at.present?
      info << "解决时间：#{major_issue.resolved_at.strftime('%Y年%m月%d日')}"
    end
    info << "创建时间：#{major_issue.created_at.strftime('%Y年%m月%d日 %H:%M')}"
    info << "\n事项描述："
    info << major_issue.description
    info.join("\n")
  end
end
