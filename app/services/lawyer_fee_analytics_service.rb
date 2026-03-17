class LawyerFeeAnalyticsService < ApplicationService
  def initialize(company: nil, lawyer: nil, date_from: nil, date_to: nil, compare_date_from: nil, compare_date_to: nil, payment_status: nil, case_type: nil, case_status: nil, fee_range: nil, invoice_status: nil, time_dimension: 'filing_at')
    @company = company
    @lawyer = lawyer
    @date_from = date_from || 30.days.ago.to_date
    @date_to = date_to || Date.today
    @compare_date_from = compare_date_from
    @compare_date_to = compare_date_to
    @payment_status = payment_status
    @case_type = case_type
    @case_status = case_status
    @fee_range = fee_range
    @invoice_status = invoice_status
    @time_dimension = time_dimension || 'filing_at'
  end
  
  def call
    {
      # 基础数据集
      base_scope: base_scope,
      period_scope: period_scope,
      
      # 核心KPI
      core_kpis: calculate_core_kpis,
      
      # 紧急预警
      urgent_alerts: calculate_urgent_alerts,
      
      # 趋势数据
      trends: calculate_trends,
      
      # 多维度分布
      distributions: calculate_distributions,
      
      # 律师工作量和律师费统计
      lawyer_workload: calculate_lawyer_workload,
      
      # 企业客户统计
      company_rankings: calculate_company_rankings,
      
      # 对比数据
      comparison: comparison_enabled? ? calculate_comparison : nil
    }
  end
  
  private
  
  def base_scope
    @base_scope ||= begin
      scope = Case.not_deleted.where.not(lawyer_fee: nil)
      scope = scope.where(company: @company) if @company
      scope = scope.filter_by_team_member(@lawyer.id) if @lawyer
      
      # 付款状态筛选
      scope = scope.where(lawyer_fee_payment_status: @payment_status) if @payment_status.present?
      
      # 案件类型筛选
      scope = scope.where(case_type: @case_type) if @case_type.present?
      
      # 案件状态筛选
      scope = scope.where(status: @case_status) if @case_status.present?
      
      # 律师费金额范围筛选
      if @fee_range.present?
        min, max = @fee_range.split('-').map(&:to_f)
        if max && max > 0
          scope = scope.where('lawyer_fee >= ? AND lawyer_fee < ?', min, max)
        else
          scope = scope.where('lawyer_fee >= ?', min)
        end
      end
      
      # 开票状态筛选
      if @invoice_status == 'issued'
        scope = scope.where(lawyer_fee_invoice_issued: true)
      elsif @invoice_status == 'not_issued'
        scope = scope.where(lawyer_fee_invoice_issued: [false, nil])
      end
      
      scope
    end
  end
  
  def period_scope
    @period_scope ||= begin
      time_field = time_dimension_field
      base_scope.where(
        "#{time_field} >= ? AND #{time_field} <= ?",
        @date_from.beginning_of_day,
        @date_to.end_of_day
      )
    end
  end
  
  def compare_scope
    return nil unless comparison_enabled?
    @compare_scope ||= begin
      time_field = time_dimension_field
      base_scope.where(
        "#{time_field} >= ? AND #{time_field} <= ?",
        @compare_date_from.beginning_of_day,
        @compare_date_to.end_of_day
      )
    end
  end
  
  def time_dimension_field
    case @time_dimension
    when 'received_at' then 'lawyer_fee_received_at'
    when 'invoice_at' then 'lawyer_fee_invoice_issued_at'
    when 'closing_at' then 'closing_at'
    else 'filing_at'
    end
  end
  
  def comparison_enabled?
    @compare_date_from.present? && @compare_date_to.present?
  end
  
  def calculate_core_kpis
    total_fee = base_scope.sum(:lawyer_fee) || 0
    total_received = base_scope.sum(:lawyer_fee_received) || 0
    pending_amount = total_fee - total_received
    
    # 计算回款率
    collection_rate = total_fee > 0 ? ((total_received.to_f / total_fee) * 100).round(1) : 0
    
    # 本月新增律师费
    current_month_start = Date.today.beginning_of_month
    current_month_fee = base_scope.where('filing_at >= ?', current_month_start).sum(:lawyer_fee) || 0
    
    # 平均回款周期（已回款案件）
    received_cases = base_scope.where(lawyer_fee_payment_status: 'completed')
      .where.not(filing_at: nil, lawyer_fee_received_at: nil)
    avg_collection_days = if received_cases.any?
      durations = received_cases.map { |c| ((c.lawyer_fee_received_at.to_time - c.filing_at.to_time) / 1.day).to_i }
      (durations.sum.to_f / durations.size).round(1)
    else
      0
    end
    
    # 案件数量
    total_cases = base_scope.count
    
    # 平均案件律师费
    avg_fee_per_case = total_cases > 0 ? (total_fee.to_f / total_cases).round(2) : 0
    
    {
      total_fee: total_fee.to_f.round(2),
      total_received: total_received.to_f.round(2),
      pending_amount: pending_amount.to_f.round(2),
      collection_rate: collection_rate,
      current_month_fee: current_month_fee.to_f.round(2),
      avg_collection_days: avg_collection_days,
      total_cases: total_cases,
      avg_fee_per_case: avg_fee_per_case
    }
  end
  
  def calculate_urgent_alerts
    # 逾期未回款（付款状态为pending或partial，且立案超过90天）
    overdue_pending = base_scope
      .where(lawyer_fee_payment_status: ['pending', 'partial'])
      .where('filing_at < ?', 90.days.ago)
      .count
    
    # 高价值未回款案件（律师费>10万且未付清）
    high_value_pending = base_scope
      .where(lawyer_fee_payment_status: ['pending', 'partial'])
      .where('lawyer_fee >= ?', 100_000)
      .count
    
    # 逾期未开票（律师费已收但未上传发票）
    overdue_invoice = base_scope
      .where(lawyer_fee_payment_status: 'completed')
      .left_joins(:lawyer_fee_invoice_attachment)
      .where(active_storage_attachments: { id: nil })
      .count
    
    {
      overdue_pending: overdue_pending,
      high_value_pending: high_value_pending,
      overdue_invoice: overdue_invoice,
      has_alerts: (overdue_pending + high_value_pending + overdue_invoice) > 0
    }
  end
  
  def calculate_trends
    time_field_method = case @time_dimension
    when 'received_at' then :lawyer_fee_received_at
    when 'invoice_at' then :lawyer_fee_invoice_issued_at
    when 'closing_at' then :closing_at
    else :filing_at
    end
    
    # 按月统计律师费收入趋势（根据选择的时间维度）
    fee_by_month = period_scope.select { |c| c.send(time_field_method).present? }
      .group_by { |c| c.send(time_field_method)&.beginning_of_month }
      .transform_values { |cases| cases.sum(&:lawyer_fee).to_f.round(2) }
      .sort.to_h
    
    # 按月统计回款趋势（始终使用回款时间）
    received_by_month = base_scope
      .where.not(lawyer_fee_received_at: nil)
      .where('lawyer_fee_received_at >= ? AND lawyer_fee_received_at <= ?', @date_from, @date_to)
      .group_by { |c| c.lawyer_fee_received_at&.beginning_of_month }
      .transform_values { |cases| cases.sum(&:lawyer_fee_received).to_f.round(2) }
      .sort.to_h
    
    {
      fee_monthly: fee_by_month,
      received_monthly: received_by_month
    }
  end
  
  def calculate_distributions
    {
      # 付款状态分布
      payment_status_distribution: base_scope.group(:lawyer_fee_payment_status).count,
      
      # 案件类型分布（按律师费金额）
      case_type_distribution: base_scope.group(:case_type)
        .sum(:lawyer_fee)
        .transform_values { |v| v.to_f.round(2) }
        .sort_by { |_, v| -v }
        .first(10)
        .to_h,
      
      # 案件状态分布
      case_status_distribution: base_scope.group(:status).count,
      
      # 律师费金额区间分布
      fee_range_distribution: {
        '0-5万' => base_scope.where('lawyer_fee < ?', 50_000).count,
        '5-10万' => base_scope.where('lawyer_fee >= ? AND lawyer_fee < ?', 50_000, 100_000).count,
        '10-20万' => base_scope.where('lawyer_fee >= ? AND lawyer_fee < ?', 100_000, 200_000).count,
        '20-50万' => base_scope.where('lawyer_fee >= ? AND lawyer_fee < ?', 200_000, 500_000).count,
        '50万以上' => base_scope.where('lawyer_fee >= ?', 500_000).count
      }
    }
  end
  
  def calculate_lawyer_workload
    return [] unless @lawyer.nil? # 只在查看全部律师时计算
    
    workload = LawyerAccount.where(role: ['lawyer', 'director', 'assistant']).map do |lawyer|
      lawyer_cases = base_scope.filter_by_team_member(lawyer.id)
      lead_cases = base_scope.filter_by_lead_lawyer(lawyer.id)
      
      total_fee = lawyer_cases.sum(:lawyer_fee).to_f.round(2)
      lead_fee = lead_cases.sum(:lawyer_fee).to_f.round(2)
      received_fee = lawyer_cases.sum(:lawyer_fee_received).to_f.round(2)
      
      {
        lawyer_id: lawyer.id,
        lawyer_name: lawyer.name,
        lawyer_role: lawyer.role,
        total_cases: lawyer_cases.count,
        lead_cases: lead_cases.count,
        total_fee: total_fee,
        lead_fee: lead_fee,
        received_fee: received_fee,
        avg_fee_per_case: lawyer_cases.count > 0 ? (total_fee / lawyer_cases.count).round(2) : 0
      }
    end
    
    workload.select { |w| w[:total_cases] > 0 }.sort_by { |w| -w[:total_fee] }.first(15)
  end
  
  def calculate_company_rankings
    return [] if @company.present?
    
    Company.joins(:cases)
      .where(cases: { deleted_at: nil })
      .where.not(cases: { lawyer_fee: nil })
      .group('companies.id', 'companies.name')
      .select('companies.id, companies.name, SUM(cases.lawyer_fee) as total_fee, COUNT(cases.id) as cases_count')
      .order('total_fee DESC')
      .limit(10)
      .map { |c| { 
        company_id: c.id, 
        company_name: c.name, 
        total_fee: c.total_fee.to_f.round(2),
        cases_count: c.cases_count 
      }}
  end
  
  def calculate_comparison
    return nil unless comparison_enabled?
    
    period_total_fee = period_scope.sum(:lawyer_fee).to_f.round(2)
    compare_total_fee = compare_scope.sum(:lawyer_fee).to_f.round(2)
    
    fee_change = period_total_fee - compare_total_fee
    fee_change_rate = compare_total_fee > 0 ? ((fee_change / compare_total_fee) * 100).round(1) : 0
    
    period_cases = period_scope.count
    compare_cases = compare_scope.count
    cases_change = period_cases - compare_cases
    
    {
      period_total_fee: period_total_fee,
      compare_total_fee: compare_total_fee,
      fee_change: fee_change,
      fee_change_rate: fee_change_rate,
      period_cases: period_cases,
      compare_cases: compare_cases,
      cases_change: cases_change
    }
  end
end
