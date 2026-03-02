class Boss::DashboardController < ApplicationController
  before_action :require_boss_role
  before_action :set_company
  
  def index
    # 案件统计
    @cases_count = @company.cases.not_deleted.count
    @cases_in_court = @company.cases.not_deleted.where(status: 'in_court').count
    @cases_recent = @company.cases.not_deleted.ordered.limit(3)
    
    # 合同统计
    @contracts_count = @company.contracts.count
    @contracts_active = @company.contracts.where(status: 'active').count
    @contracts_expiring_soon = @company.contracts.where('end_at BETWEEN ? AND ?', Date.today, 30.days.from_now).count
    
    # 计算待上传对账单的合同数量
    @contracts_need_reconciliation = @company.contracts.select do |contract|
      contract.cross_month? && !contract.reconciliation_uploaded_this_month?
    end.count
    
    # 重大事项统计
    @major_issues_count = @company.major_issues.not_deleted.count
    @major_issues_pending = @company.major_issues.not_deleted.where(status: 'pending').count
    @major_issues_high_priority = @company.major_issues.not_deleted.high_priority.count
    @major_issues_recent = @company.major_issues.not_deleted.ordered.limit(3)
    
    # 待办事项统计
    todo_service = CompanyTodoService.new(company: @company)
    todo_data = todo_service.call
    @todo_stats = todo_data[:stats]
    
    # 风险提醒（最多5条）
    @urgent_alerts = build_urgent_alerts
  end
  
  private
  
  def set_company
    @company = current_company_user.company
  end
  
  def build_urgent_alerts
    alerts = []
    
    # 优先级1: 即将开庭的案件
    @company.cases.not_deleted.where('hearing_at BETWEEN ? AND ?', Time.current, 7.days.from_now).order(:hearing_at).limit(2).each do |case_record|
      days_left = ((case_record.hearing_at - Time.current) / 1.day).ceil
      alerts << {
        type: 'danger',
        message: "案件「#{case_record.name}」将于 #{case_record.hearing_at.strftime('%Y-%m-%d %H:%M')} 开庭（#{days_left}天后）",
        link: case_path(case_record)
      }
    end
    
    # 优先级2: 已过期的业务合同
    @company.contracts.where('end_at < ?', Date.today).order(:end_at).limit(2).each do |contract|
      alerts << {
        type: 'danger',
        message: "合同「#{contract.name}」已于 #{contract.end_at.strftime('%Y-%m-%d')} 过期，请立即处理",
        link: contract_path(contract)
      }
    end
    
    # 优先级3: 紧急重大事项
    @company.major_issues.not_deleted.where(priority: 'urgent', status: 'pending').limit(2).each do |issue|
      alerts << {
        type: 'warning',
        message: "紧急事项「#{issue.title}」待处理",
        link: major_issue_path(issue)
      }
    end
    
    # 优先级4: 7天内到期的业务合同
    @company.contracts.where('end_at BETWEEN ? AND ?', Date.today, 7.days.from_now).order(:end_at).limit(2).each do |contract|
      days_left = (contract.end_at - Date.today).to_i
      alerts << {
        type: 'warning',
        message: "合同「#{contract.name}」将于 #{contract.end_at.strftime('%Y-%m-%d')} 到期（#{days_left}天后）",
        link: contract_path(contract)
      }
    end
    
    # 优先级5: 待上传对账单（取最多2个）
    cross_month_contracts = @company.contracts.select do |contract|
      contract.cross_month? && !contract.reconciliation_uploaded_this_month?
    end
    cross_month_contracts.first(2).each do |contract|
      alerts << {
        type: 'info',
        message: "合同「#{contract.name}」本月对账单待上传",
        link: contract_path(contract)
      }
    end
    
    alerts.take(5) # 最多显示5条
  end
end
