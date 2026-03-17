class ContractRisksController < ApplicationController
  before_action :require_lawyer_or_boss

  def dashboard
    # 获取企业范围（如果有选择）
    @company = if lawyer?
      session[:viewing_company_id] ? Company.find_by(id: session[:viewing_company_id]) : nil
    else
      current_company_user.company
    end

    # 获取风险分析数据
    service = ContractRiskAnalyticService.new(company: @company)
    @risk_data = service.call

    # 直接访问各个数据
    @summary = @risk_data[:summary]
    @high_risk_contracts = @risk_data[:high_risk_contracts]
    @expiring_contracts = @risk_data[:expiring_contracts]
    @overdue_reconciliations = @risk_data[:overdue_reconciliations]
    @dispute_contracts = @risk_data[:dispute_contracts]
    @recent_unreviewed = @risk_data[:recent_unreviewed]
  end

  private

  def require_lawyer_or_boss
    return if lawyer?
    return if current_company_user&.boss?
    redirect_to root_path, alert: "无权访问"
  end
end
