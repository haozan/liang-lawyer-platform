class Boss::DashboardController < ApplicationController
  before_action :require_boss_role
  before_action :set_company
  
  def index
    # 员工统计
    @employees_count = @company.employees.count
    @employees_expiring_soon = @company.employees.where('contract_end_at BETWEEN ? AND ?', Date.today, 30.days.from_now)
    @employees_expired = @company.employees.where('contract_end_at < ?', Date.today)
    @employees_new_this_month = @company.employees.where('hired_at >= ?', Date.today.beginning_of_month).count
    
    # 合同统计
    @contracts_count = @company.contracts.count
    @contracts_expiring_soon = @company.contracts.where('end_at BETWEEN ? AND ?', Date.today, 30.days.from_now)
    @contracts_in_risk = @company.contracts.where(status: ['litigation', 'breach'])
    
    # 计算待上传对账单的合同数量
    @contracts_need_reconciliation = @company.contracts.select do |contract|
      contract.cross_month? && !contract.reconciliation_uploaded_this_month?
    end.count
    
    # 规章制度统计
    @regulations_count = @company.regulations.count
    @regulations_latest = @company.regulations.order(updated_at: :desc).first
    @regulations_new_this_month = @company.regulations.where('created_at >= ?', Date.today.beginning_of_month).count
    
    # 风险提醒（最多5条）
    @urgent_alerts = build_urgent_alerts
  end
  
  private
  
  def set_company
    @company = current_company_user.company
  end
  
  def build_urgent_alerts
    alerts = []
    
    # 优先级1: 已过期的劳动合同
    @company.employees.where('contract_end_at < ?', Date.today).order(:contract_end_at).limit(2).each do |emp|
      alerts << {
        type: 'danger',
        message: "#{emp.name}的劳动合同已于 #{emp.contract_end_at.strftime('%Y-%m-%d')} 过期，请立即处理",
        link: employee_path(emp)
      }
    end
    
    # 优先级2: 已过期的业务合同
    @company.contracts.where('end_at < ?', Date.today).order(:end_at).limit(2).each do |contract|
      alerts << {
        type: 'danger',
        message: "#{contract.name} 已于 #{contract.end_at.strftime('%Y-%m-%d')} 过期，请立即处理",
        link: contract_path(contract)
      }
    end
    
    # 优先级3: 7天内到期的劳动合同
    @company.employees.where('contract_end_at BETWEEN ? AND ?', Date.today, 7.days.from_now).order(:contract_end_at).each do |emp|
      days_left = (emp.contract_end_at - Date.today).to_i
      alerts << {
        type: 'warning',
        message: "#{emp.name}的劳动合同将于 #{emp.contract_end_at.strftime('%Y-%m-%d')} 到期（#{days_left}天后），请及时续签",
        link: employee_path(emp)
      }
    end
    
    # 优先级4: 7天内到期的业务合同
    @company.contracts.where('end_at BETWEEN ? AND ?', Date.today, 7.days.from_now).order(:end_at).each do |contract|
      days_left = (contract.end_at - Date.today).to_i
      alerts << {
        type: 'warning',
        message: "#{contract.name} 将于 #{contract.end_at.strftime('%Y-%m-%d')} 到期（#{days_left}天后），请关注",
        link: contract_path(contract)
      }
    end
    
    # 优先级5: 诉讼/违约合同
    @company.contracts.where(status: ['litigation', 'breach']).limit(2).each do |contract|
      alerts << {
        type: 'danger',
        message: "#{contract.name} 处于#{contract.status_display}状态，请及时处理",
        link: contract_path(contract)
      }
    end
    
    # 优先级6: 待上传对账单（取最多2个）
    cross_month_contracts = @company.contracts.select do |contract|
      contract.cross_month? && !contract.reconciliation_uploaded_this_month?
    end
    cross_month_contracts.first(2).each do |contract|
      alerts << {
        type: 'info',
        message: "#{contract.name} 本月未上传对账单，请尽快上传",
        link: contract_path(contract)
      }
    end
    
    alerts.take(5) # 最多显示5条
  end
end
