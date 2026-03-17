class ContractAnalyticsService < ApplicationService
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
      
      # 风险预警
      risk_alerts: calculate_risk_alerts,
      
      # 趋势数据
      trends: calculate_trends,
      
      # 多维度分布
      distributions: calculate_distributions,
      
      # 金额统计
      amount_statistics: calculate_amount_statistics,
      
      # 律师审查统计
      lawyer_review_stats: calculate_lawyer_review_stats,
      
      # 企业排行（仅律师可见）
      company_rankings: calculate_company_rankings,
      
      # 对比数据
      comparison: comparison_enabled? ? calculate_comparison : nil,
      
      # 导出数据
      export_data: prepare_export_data
    }
  end
  
  private
  
  def base_scope
    @base_scope ||= begin
      scope = Contract.all
      scope = scope.where(company: @company) if @company
      scope = scope.where(assigned_lawyer: @lawyer) if @lawyer
      scope
    end
  end
  
  def period_scope
    @period_scope ||= base_scope.where(
      'signed_at >= ? AND signed_at <= ?',
      @date_from.beginning_of_day,
      @date_to.end_of_day
    )
  end
  
  def compare_scope
    return nil unless comparison_enabled?
    @compare_scope ||= base_scope.where(
      'signed_at >= ? AND signed_at <= ?',
      @compare_date_from.beginning_of_day,
      @compare_date_to.end_of_day
    )
  end
  
  def comparison_enabled?
    @compare_date_from.present? && @compare_date_to.present?
  end
  
  def calculate_core_kpis
    total = base_scope.count
    active = base_scope.active.count
    completed = base_scope.completed.count
    breach = base_scope.breach.count
    litigation = base_scope.litigation.count
    
    # 合同总金额（执行中的合同）
    total_amount = base_scope.active.sum(:contract_amount) || 0
    
    # 本月新签
    current_month_start = Date.today.beginning_of_month
    current_month_count = base_scope.where('signed_at >= ?', current_month_start).count
    
    {
      total_contracts: total,
      active_contracts: active,
      completed_contracts: completed,
      breach_contracts: breach,
      litigation_contracts: litigation,
      total_amount: total_amount,
      current_month_new: current_month_count
    }
  end
  
  def calculate_risk_alerts
    # 即将到期（30天内）
    expiring_soon = base_scope.expiring_soon.count
    
    # 高风险合同
    high_risk = base_scope.where(legal_risk_level: ['高', '极高']).count
    
    # 逾期未审查（创建超过3天但未审查）
    overdue_review = base_scope.where(reviewed_by_lawyer: false)
      .where('created_at < ?', 3.days.ago)
      .count
    
    # 对账单逾期
    overdue_reconciliation = base_scope.active.select(&:reconciliation_overdue?).count
    
    {
      expiring_soon: expiring_soon,
      high_risk: high_risk,
      overdue_review: overdue_review,
      overdue_reconciliation: overdue_reconciliation,
      has_alerts: (expiring_soon + high_risk + overdue_review + overdue_reconciliation) > 0
    }
  end
  
  def calculate_trends
    # 签订趋势（按日统计）
    signing_trend = {}
    current_date = @date_from
    while current_date <= @date_to
      count = base_scope.where(
        signed_at: current_date.beginning_of_day..current_date.end_of_day
      ).count
      signing_trend[current_date] = count
      current_date = current_date.next_day
    end
    
    # 到期趋势（按日统计）
    expiry_trend = {}
    current_date = @date_from
    while current_date <= @date_to
      count = base_scope.where(
        end_at: current_date.beginning_of_day..current_date.end_of_day
      ).count
      expiry_trend[current_date] = count
      current_date = current_date.next_day
    end
    
    # 金额趋势（按月统计）
    amount_by_month = {}
    period_scope.group_by { |c| c.signed_at&.beginning_of_month }.each do |month, contracts|
      amount_by_month[month] = contracts.select { |c| c.contract_amount.present? }.sum(&:contract_amount)
    end
    amount_by_month = amount_by_month.sort.to_h
    
    {
      signing_daily: signing_trend,
      expiry_daily: expiry_trend,
      amount_monthly: amount_by_month
    }
  end
  
  def calculate_distributions
    {
      # 合同类型分布
      contract_type_distribution: base_scope.group(:contract_type).count,
      
      # 状态分布
      status_distribution: base_scope.group(:status).count,
      
      # 风险等级分布
      risk_level_distribution: base_scope.where.not(legal_risk_level: nil).group(:legal_risk_level).count,
      
      # 履行状态分布
      performance_status_distribution: base_scope.where.not(performance_status: nil).group(:performance_status).count,
      
      # 争议状态分布
      dispute_status_distribution: base_scope.where.not(dispute_status: nil).group(:dispute_status).count,
      
      # 对方类型分布
      counterparty_type_distribution: base_scope.where.not(counterparty_type: nil).group(:counterparty_type).count
    }
  end
  
  def calculate_amount_statistics
    contracts_with_amount = base_scope.where.not(contract_amount: nil)
    
    total_amount = contracts_with_amount.sum(:contract_amount) || 0
    avg_amount = contracts_with_amount.any? ? (total_amount.to_f / contracts_with_amount.count).round(2) : 0
    max_amount = contracts_with_amount.maximum(:contract_amount) || 0
    min_amount = contracts_with_amount.minimum(:contract_amount) || 0
    
    # 按金额区间分布
    amount_ranges = {
      '10万以下': contracts_with_amount.where('contract_amount < ?', 100000).count,
      '10-50万': contracts_with_amount.where('contract_amount >= ? AND contract_amount < ?', 100000, 500000).count,
      '50-100万': contracts_with_amount.where('contract_amount >= ? AND contract_amount < ?', 500000, 1000000).count,
      '100-500万': contracts_with_amount.where('contract_amount >= ? AND contract_amount < ?', 1000000, 5000000).count,
      '500万以上': contracts_with_amount.where('contract_amount >= ?', 5000000).count
    }
    
    {
      total_amount: total_amount,
      avg_amount: avg_amount,
      max_amount: max_amount,
      min_amount: min_amount,
      amount_ranges: amount_ranges
    }
  end
  
  def calculate_lawyer_review_stats
    total = base_scope.count
    reviewed = base_scope.where(reviewed_by_lawyer: true).count
    pending_review = base_scope.where(reviewed_by_lawyer: false).count
    
    # 审查及时率（3天内完成审查的比例）
    timely_reviewed = base_scope.where(reviewed_by_lawyer: true)
      .where('reviewed_at_lawyer <= created_at + INTERVAL \'3 days\'')
      .count
    timeliness_rate = reviewed > 0 ? ((timely_reviewed.to_f / reviewed) * 100).round(1) : 0
    
    # 平均审查时长（天）
    reviewed_contracts = base_scope.where(reviewed_by_lawyer: true)
      .where.not(reviewed_at_lawyer: nil)
    avg_review_days = if reviewed_contracts.any?
      durations = reviewed_contracts.map { |c| ((c.reviewed_at_lawyer - c.created_at) / 1.day).to_i }
      (durations.sum.to_f / durations.size).round(1)
    else
      0
    end
    
    {
      total: total,
      reviewed: reviewed,
      pending_review: pending_review,
      review_rate: total > 0 ? ((reviewed.to_f / total) * 100).round(1) : 0,
      timeliness_rate: timeliness_rate,
      avg_review_days: avg_review_days
    }
  end
  
  def calculate_company_rankings
    return { by_count: [], by_amount: [] } if @company.present? # 单企业模式不显示排行
    
    # 按合同数量排行
    by_count = Company.joins(:contracts)
      .group('companies.id', 'companies.name')
      .select('companies.id, companies.name, COUNT(contracts.id) as contracts_count')
      .order('contracts_count DESC')
      .limit(10)
      .map { |c| { company_id: c.id, company_name: c.name, contracts_count: c.contracts_count } }
    
    # 按合同金额排行
    by_amount = Company.joins(:contracts)
      .where.not(contracts: { contract_amount: nil })
      .group('companies.id', 'companies.name')
      .select('companies.id, companies.name, SUM(contracts.contract_amount) as total_amount')
      .order('total_amount DESC')
      .limit(10)
      .map { |c| { company_id: c.id, company_name: c.name, total_amount: c.total_amount.to_f } }
    
    {
      by_count: by_count,
      by_amount: by_amount
    }
  end
  
  def calculate_comparison
    return nil unless comparison_enabled?
    
    compare_total = compare_scope.count
    compare_amount = compare_scope.sum(:contract_amount) || 0
    
    current_total = period_scope.count
    current_amount = period_scope.sum(:contract_amount) || 0
    
    {
      period_total: current_total,
      compare_total: compare_total,
      total_change: current_total - compare_total,
      total_change_rate: compare_total > 0 ? (((current_total - compare_total).to_f / compare_total) * 100).round(1) : 0,
      
      period_amount: current_amount,
      compare_amount: compare_amount,
      amount_change: current_amount - compare_amount,
      amount_change_rate: compare_amount > 0 ? (((current_amount - compare_amount).to_f / compare_amount) * 100).round(1) : 0
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
