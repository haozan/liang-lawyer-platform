class CaseAnalyticsService < ApplicationService
  def initialize(company: nil, lawyer: nil, date_from: nil, date_to: nil, compare_date_from: nil, compare_date_to: nil)
    @company = company
    @lawyer = lawyer
    @date_from = date_from || 30.days.ago.to_date
    @date_to = date_to || Date.today
    @compare_date_from = compare_date_from
    @compare_date_to = compare_date_to
  end
  
  def call
    {
      # 基础数据集
      base_scope: base_scope,
      period_scope: period_scope,
      compare_scope: compare_scope,
      
      # 核心KPI
      core_kpis: calculate_core_kpis,
      
      # 紧急预警
      urgent_alerts: calculate_urgent_alerts,
      
      # 趋势数据
      trends: calculate_trends,
      
      # 多维度分布
      distributions: calculate_distributions,
      
      # 团队工作量
      team_workload: calculate_team_workload,
      
      # 企业排行（仅律师可见）
      company_rankings: calculate_company_rankings,
      
      # 关键节点统计
      key_milestones: calculate_key_milestones,
      
      # 对比数据（如果提供了对比时间范围）
      comparison: comparison_enabled? ? calculate_comparison : nil,
      
      # 导出数据
      export_data: prepare_export_data
    }
  end
  
  private
  
  def base_scope
    @base_scope ||= begin
      scope = Case.not_deleted
      scope = scope.where(company: @company) if @company
      scope = scope.filter_by_team_member(@lawyer.id) if @lawyer
      scope
    end
  end
  
  def period_scope
    @period_scope ||= base_scope.where(
      'filing_at >= ? AND filing_at <= ?', 
      @date_from.beginning_of_day, 
      @date_to.end_of_day
    )
  end
  
  def compare_scope
    return nil unless comparison_enabled?
    @compare_scope ||= base_scope.where(
      'filing_at >= ? AND filing_at <= ?',
      @compare_date_from.beginning_of_day,
      @compare_date_to.end_of_day
    )
  end
  
  def comparison_enabled?
    @compare_date_from.present? && @compare_date_to.present?
  end
  
  def calculate_core_kpis
    total = base_scope.count
    active = base_scope.where(status: ['investigating', 'in_court']).count
    closed = base_scope.where(status: 'closed').count
    pending = base_scope.where(status: 'pending').count
    
    # 平均处理时长（已结案案件）
    closed_cases = base_scope.where(status: 'closed').where.not(filing_at: nil, closing_at: nil)
    avg_duration = if closed_cases.any?
      durations = closed_cases.map { |c| ((c.closing_at.to_time - c.filing_at.to_time) / 1.day).to_i }
      (durations.sum.to_f / durations.size).round(1)
    else
      0
    end
    
    # 完成率
    completion_rate = total > 0 ? ((closed.to_f / total) * 100).round(1) : 0
    
    # 本月新增
    current_month_start = Date.today.beginning_of_month
    current_month_count = base_scope.where('filing_at >= ?', current_month_start).count
    
    {
      total_cases: total,
      active_cases: active,
      closed_cases: closed,
      pending_cases: pending,
      avg_duration_days: avg_duration,
      completion_rate: completion_rate,
      current_month_new: current_month_count
    }
  end
  
  def calculate_urgent_alerts
    # 逾期开庭（开庭日期已过但案件仍在庭审中）
    overdue_hearings = base_scope.where(status: 'in_court')
      .where('hearing_at < ?', Date.today)
      .where.not(hearing_at: nil)
      .count
    
    # 逾期判决书领取（判决书领取日期已过但案件未结案）
    overdue_judgements = base_scope.where(status: 'judged')
      .where('judgement_received_at < ?', 30.days.ago)
      .where.not(judgement_received_at: nil)
      .count
    
    # 高优先级待处理
    urgent_pending = base_scope.where(priority: 'urgent')
      .where(status: ['preparing', 'filed'])
      .count
    
    {
      overdue_hearings: overdue_hearings,
      overdue_judgements: overdue_judgements,
      urgent_pending: urgent_pending,
      has_alerts: (overdue_hearings + overdue_judgements + urgent_pending) > 0
    }
  end
  
  def calculate_trends
    # 立案趋势（按日统计）
    filing_trend = {}
    current_date = @date_from
    while current_date <= @date_to
      count = base_scope.where(
        filing_at: current_date.beginning_of_day..current_date.end_of_day
      ).count
      filing_trend[current_date] = count
      current_date = current_date.next_day
    end
    
    # 结案趋势（按日统计）
    closing_trend = {}
    current_date = @date_from
    while current_date <= @date_to
      count = base_scope.where(status: 'closed')
        .where(closing_at: current_date.beginning_of_day..current_date.end_of_day)
        .count
      closing_trend[current_date] = count
      current_date = current_date.next_day
    end
    
    # 按月统计（用于长时间跨度）
    filing_by_month = period_scope.group_by { |c| c.filing_at&.beginning_of_month }
      .transform_values(&:count)
      .sort.to_h
    
    {
      filing_daily: filing_trend,
      closing_daily: closing_trend,
      filing_monthly: filing_by_month
    }
  end
  
  def calculate_distributions
    {
      # 案件阶段分布
      stage_distribution: base_scope.where.not(stage: nil).group(:stage).count,
      
      # 诉讼地位分布
      party_role_distribution: base_scope.where.not(our_party_role: nil).group(:our_party_role).count,
      
      # 案件类型分布（TOP 10）
      case_type_distribution: base_scope.group(:case_type).count.sort_by { |_, v| -v }.first(10).to_h,
      
      # 状态分布
      status_distribution: base_scope.group(:status).count,
      
      # 优先级分布
      priority_distribution: base_scope.group(:priority).count
    }
  end
  
  def calculate_team_workload
    return {} unless @lawyer.nil? # 只在查看全部案件时计算
    
    workload = LawyerAccount.where(role: 'lawyer').map do |lawyer|
      total_cases = base_scope.filter_by_team_member(lawyer.id).count
      lead_cases = base_scope.filter_by_lead_lawyer(lawyer.id).count
      active_cases = base_scope.filter_by_team_member(lawyer.id)
        .where(status: ['filed', 'trial', 'judged', 'execution']).count
      
      {
        lawyer_id: lawyer.id,
        lawyer_name: lawyer.name,
        total_cases: total_cases,
        lead_cases: lead_cases,
        active_cases: active_cases
      }
    end
    
    workload.sort_by { |w| -w[:total_cases] }.first(10)
  end
  
  def calculate_company_rankings
    return [] if @company.present? # 单企业模式不显示排行
    
    Company.joins(:cases)
      .where(cases: { deleted_at: nil })
      .group('companies.id', 'companies.name')
      .select('companies.id, companies.name, COUNT(cases.id) as cases_count')
      .order('cases_count DESC')
      .limit(10)
      .map { |c| { company_id: c.id, company_name: c.name, cases_count: c.cases_count } }
  end
  
  def calculate_key_milestones
    # 本月开庭案件数
    month_hearings = base_scope.where(
      hearing_at: Date.today.beginning_of_month..Date.today.end_of_month
    ).count
    
    # 本月判决案件数
    month_judgements = base_scope.where(status: 'judged')
      .where(judgement_received_at: Date.today.beginning_of_month..Date.today.end_of_month)
      .count
    
    # 待执行案件数
    pending_execution = base_scope.where(stage: 'execution', status: ['filed', 'trial', 'judged', 'execution']).count
    
    # 财产保全案件数
    property_preservation_count = base_scope.where.not(property_preservation_applied_at: nil).count
    
    {
      month_hearings: month_hearings,
      month_judgements: month_judgements,
      pending_execution: pending_execution,
      property_preservation_count: property_preservation_count
    }
  end
  
  def calculate_comparison
    return nil unless comparison_enabled?
    
    compare_total = compare_scope.count
    compare_closed = compare_scope.where(status: 'closed').count
    
    current_total = period_scope.count
    current_closed = period_scope.where(status: 'closed').count
    
    {
      period_total: current_total,
      compare_total: compare_total,
      total_change: current_total - compare_total,
      total_change_rate: compare_total > 0 ? (((current_total - compare_total).to_f / compare_total) * 100).round(1) : 0,
      
      period_closed: current_closed,
      compare_closed: compare_closed,
      closed_change: current_closed - compare_closed,
      closed_change_rate: compare_closed > 0 ? (((current_closed - compare_closed).to_f / compare_closed) * 100).round(1) : 0
    }
  end
  
  def prepare_export_data
    {
      generated_at: Time.current,
      date_range: "#{@date_from} 至 #{@date_to}",
      company_name: @company&.name || '全部企业',
      lawyer_name: @lawyer&.name,
      total_records: base_scope.count
    }
  end
end
