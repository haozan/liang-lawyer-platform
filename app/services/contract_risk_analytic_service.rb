class ContractRiskAnalyticService < ApplicationService
  # 合同风险分析服务
  # 提供合同风险统计、高风险合同列表等数据分析
  
  def initialize(company: nil)
    @company = company
  end

  def call
    {
      summary: summary_statistics,
      high_risk_contracts: high_risk_contracts_data,
      expiring_contracts: expiring_contracts_data,
      overdue_reconciliations: overdue_reconciliations_data,
      dispute_contracts: dispute_contracts_data,
      recent_unreviewed: recent_unreviewed_contracts_data
    }
  end

  private

  def base_scope
    @company ? @company.contracts : Contract.all
  end

  # 总体统计数据
  def summary_statistics
    {
      total_active: base_scope.active.count,
      high_risk_count: base_scope.active.where(legal_risk_level: ['高', '极高']).count,
      expiring_soon_count: base_scope.expiring_soon.count,
      overdue_reconciliation_count: base_scope.active.select(&:reconciliation_overdue?).count,
      dispute_count: base_scope.active.where.not(dispute_status: [nil, '无争议']).count,
      unreviewed_count: base_scope.pending_lawyer_review.count
    }
  end

  # 高风险合同列表（风险等级为高或极高）
  def high_risk_contracts_data
    base_scope
      .active
      .where(legal_risk_level: ['高', '极高'])
      .order(Arel.sql("CASE legal_risk_level WHEN '极高' THEN 0 WHEN '高' THEN 1 END"), created_at: :desc)
      .limit(10)
      .map { |c| contract_summary(c) }
  end

  # 即将到期的合同
  def expiring_contracts_data
    base_scope
      .expiring_soon
      .order(end_at: :asc)
      .limit(10)
      .map { |c| contract_summary(c) }
  end

  # 对账单逾期的合同
  def overdue_reconciliations_data
    contracts = base_scope
      .active
      .where('signed_at < ?', Time.current.beginning_of_month)
      .select { |c| c.cross_month? && c.reconciliation_overdue? }
      .sort_by { |c| c.signed_at }
      .first(10)
    
    contracts.map { |c| contract_summary(c) }
  end

  # 有争议的合同
  def dispute_contracts_data
    base_scope
      .active
      .where.not(dispute_status: [nil, '无争议'])
      .order(dispute_occurred_at: :desc)
      .limit(10)
      .map { |c| contract_summary(c) }
  end

  # 最近未审查的合同
  def recent_unreviewed_contracts_data
    base_scope
      .pending_lawyer_review
      .order(created_at: :desc)
      .limit(10)
      .map { |c| contract_summary(c) }
  end

  # 合同摘要信息
  def contract_summary(contract)
    {
      id: contract.id,
      name: contract.name,
      company_name: contract.company.name,
      counterparty_name: contract.counterparty_name,
      signed_at: contract.signed_at,
      end_at: contract.end_at,
      status: contract.status,
      legal_risk_level: contract.legal_risk_level,
      dispute_status: contract.dispute_status,
      performance_status: contract.performance_status,
      expiring_soon: contract.expiring_soon?,
      expired: contract.expired?,
      reconciliation_overdue: contract.reconciliation_overdue?,
      reviewed_by_lawyer: contract.reviewed_by_lawyer
    }
  end
end
