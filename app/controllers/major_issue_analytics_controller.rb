class MajorIssueAnalyticsController < ApplicationController
  before_action :require_authentication
  before_action :set_company

  def dashboard
    # 时间范围设置（默认最近30天）
    @date_from = params[:date_from]&.to_date || 30.days.ago.to_date
    @date_to = params[:date_to]&.to_date || Date.today
    
    # 基础数据集
    issues = if @company
               @company.major_issues.not_deleted
             else
               MajorIssue.not_deleted
             end
    
    # 按时间范围筛选
    issues_in_range = issues.where(created_at: @date_from.beginning_of_day..@date_to.end_of_day)
    
    # 1. 基本统计
    @total_issues = issues.count
    @issues_in_period = issues_in_range.count
    @pending_issues = issues.pending.count
    @discussing_issues = issues.discussing.count
    @resolved_issues = issues.resolved.count
    @archived_issues = issues.where(status: 'archived').count
    @overdue_issues = issues.where('processing_days > 7').where.not(status: 'resolved').count
    
    # 2. 优先级分布
    @priority_distribution = issues.group(:priority).count
    
    # 3. 状态分布
    @status_distribution = issues.group(:status).count
    
    # 4. 事项类型分布
    @issue_type_distribution = issues.group(:issue_type).count.sort_by { |_, count| -count }.first(10)
    @category_distribution = @issue_type_distribution.to_h
    
    # 5. 趋势数据（按天统计创建数量）
    @daily_creation_trend = issues_in_range.group_by_day(:created_at, range: @date_from..@date_to).count
    
    # 6. 趋势数据（按天统计解决数量）
    resolved_in_range = issues.where(resolved_at: @date_from..@date_to)
    @daily_resolution_trend = resolved_in_range.group_by_day(:resolved_at, range: @date_from..@date_to).count
    
    # 7. 平均处理时间
    resolved_with_days = issues.resolved.where.not(processing_days: nil)
    @avg_processing_days = resolved_with_days.average(:processing_days)&.round(1) || 0
    @max_processing_days = resolved_with_days.maximum(:processing_days) || 0
    @min_processing_days = resolved_with_days.minimum(:processing_days) || 0
    
    # 8. 律师工作量统计
    lawyer_stats = {}
    LawyerAccount.where(role: 'lawyer').each do |lawyer|
      mentioned_count = issues.where(mentioned_lawyer_id: lawyer.id).count
      reviewed_count = issues.where(reviewed_by_lawyer_id: lawyer.id).count
      lawyer_stats[lawyer.name] = {
        mentioned: mentioned_count,
        reviewed: reviewed_count,
        total: mentioned_count + reviewed_count
      }
    end
    @lawyer_workload = lawyer_stats.sort_by { |_, stats| -stats[:total] }.first(10)
    
    # 9. 答复及时率
    total_needing_review = issues.count
    reviewed_on_time = issues.where('reviewed_at IS NOT NULL AND reviewed_at <= created_at + INTERVAL \'3 days\'').count
    @review_timeliness_rate = total_needing_review > 0 ? (reviewed_on_time.to_f / total_needing_review * 100).round(1) : 0
    
    # 10. 本月新增趋势
    current_month_start = Date.today.beginning_of_month
    @current_month_issues = issues.where('created_at >= ?', current_month_start).count
    last_month_start = 1.month.ago.beginning_of_month
    last_month_end = 1.month.ago.end_of_month
    @last_month_issues = issues.where(created_at: last_month_start..last_month_end).count
    
    if @last_month_issues > 0
      @month_growth_rate = ((@current_month_issues - @last_month_issues).to_f / @last_month_issues * 100).round(1)
    else
      @month_growth_rate = 0
    end
    
    # 11. 完成率
    total_with_status = issues.count
    @completion_rate = total_with_status > 0 ? (@resolved_issues.to_f / total_with_status * 100).round(1) : 0
    
    # 12. 负责人事项分布（按提及的律师统计）
    @responsible_party_distribution = issues
      .joins("LEFT JOIN lawyer_accounts ON lawyer_accounts.id = major_issues.mentioned_lawyer_id")
      .group('lawyer_accounts.name')
      .count
      .reject { |k, _| k.nil? }
      .sort_by { |_, count| -count }
      .first(10)
      .to_h
    
    # 13. 企业TOP10（仅律师可见）
    if lawyer?
      @company_rankings = Company.joins(:major_issues)
        .where(major_issues: { deleted_at: nil })
        .group('companies.id', 'companies.name')
        .select('companies.id, companies.name, COUNT(major_issues.id) as issues_count')
        .order('issues_count DESC')
        .limit(10)
        .map { |c| { company_id: c.id, company_name: c.name, issues_count: c.issues_count } }
    else
      @company_rankings = []
    end
  end

  private

  def require_authentication
    unless current_user || current_lawyer
      redirect_to login_path, alert: '请先登录'
    end
  end

  def set_company
    @company = if current_company_user
                 current_company_user.company
               elsif current_lawyer && params[:company_id].present? && params[:company_id] != 'all'
                 Company.find(params[:company_id])
               else
                 nil
               end
  end
end
