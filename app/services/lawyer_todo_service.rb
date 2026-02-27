class LawyerTodoService < ApplicationService
  def initialize(company_id: nil)
    @company_id = company_id
  end

  def call
    {
      stats: calculate_stats,
      urgent_items: urgent_items,
      pending_contracts: pending_contracts,
      pending_employees: pending_employees,
      pending_regulations: pending_regulations,
      company_todos: company_todos
    }
  end

  private

  def calculate_stats
    all_pending = all_pending_items
    
    {
      today_new: all_pending.select { |item| item[:record].created_at >= Time.current.beginning_of_day }.count,
      total_pending: all_pending.count,
      this_week_reviewed: reviewed_this_week_count,
      overdue: all_pending.select { |item| item[:record].overdue_for_review? }.count
    }
  end

  def urgent_items
    items = []
    
    # 高优先级：员工合同即将到期
    employees_scope.expiring_soon.pending_lawyer_review.each do |employee|
      items << {
        type: :employee,
        priority: 0,
        record: employee,
        company: employee.company,
        message: "员工#{employee.name}合同#{days_until(employee.contract_end_at)}天后到期",
        overdue: employee.overdue_for_review?,
        overdue_days: employee.overdue_days,
        link: employee_path_with_company(employee)
      }
    end
    
    # 高优先级：合同即将到期
    contracts_scope.expiring_soon.pending_lawyer_review.each do |contract|
      items << {
        type: :contract,
        priority: 0,
        record: contract,
        company: contract.company,
        message: "合同《#{contract.name}》#{days_until(contract.end_at)}天后到期",
        overdue: contract.overdue_for_review?,
        overdue_days: contract.overdue_days,
        link: contract_path_with_company(contract)
      }
    end
    
    # 高优先级：对账单逾期
    contracts_scope.active.pending_lawyer_review.each do |contract|
      if contract.reconciliation_overdue?
        items << {
          type: :contract,
          priority: 0,
          record: contract,
          company: contract.company,
          message: "合同《#{contract.name}》本月对账单逾期未上传",
          overdue: contract.overdue_for_review?,
          overdue_days: contract.overdue_days,
          link: contract_path_with_company(contract)
        }
      end
    end
    
    # 按逾期天数和创建时间排序
    items.sort_by { |item| [-item[:overdue_days], item[:record].created_at] }
  end

  def pending_contracts
    items = []
    
    contracts_scope.new_files.pending_lawyer_review.each do |contract|
      next if contract.lawyer_review_priority == 0 # 跳过已在紧急事项中的
      
      items << {
        type: :contract,
        priority: 1,
        record: contract,
        company: contract.company,
        message: "新合同《#{contract.name}》待审查",
        overdue: contract.overdue_for_review?,
        overdue_days: contract.overdue_days,
        link: contract_path_with_company(contract),
        created_ago: time_ago_in_words(contract.created_at)
      }
    end
    
    items.sort_by { |item| [-item[:overdue_days], item[:record].created_at] }
  end

  def pending_employees
    items = []
    
    employees_scope.new_files.pending_lawyer_review.each do |employee|
      next if employee.contract_expiring_soon? # 跳过已在紧急事项中的
      
      items << {
        type: :employee,
        priority: 2,
        record: employee,
        company: employee.company,
        message: "新员工档案《#{employee.name}》待审查",
        overdue: employee.overdue_for_review?,
        overdue_days: employee.overdue_days,
        link: employee_path_with_company(employee),
        created_ago: time_ago_in_words(employee.created_at)
      }
    end
    
    items.sort_by { |item| [-item[:overdue_days], item[:record].created_at] }
  end

  def pending_regulations
    items = []
    
    regulations_scope.new_files.pending_lawyer_review.each do |regulation|
      items << {
        type: :regulation,
        priority: 2,
        record: regulation,
        company: regulation.company,
        message: "新规章制度《#{regulation.name}》待审查",
        overdue: regulation.overdue_for_review?,
        overdue_days: regulation.overdue_days,
        link: regulation_path_with_company(regulation),
        created_ago: time_ago_in_words(regulation.created_at)
      }
    end
    
    items.sort_by { |item| [-item[:overdue_days], item[:record].created_at] }
  end

  def company_todos
    companies = @company_id ? Company.where(id: @company_id) : Company.all
    
    companies.map do |company|
      urgent = urgent_items.select { |item| item[:company].id == company.id }.count
      contracts = pending_contracts.select { |item| item[:company].id == company.id }.count
      employees = pending_employees.select { |item| item[:company].id == company.id }.count
      regulations = pending_regulations.select { |item| item[:company].id == company.id }.count
      
      {
        company: company,
        urgent_count: urgent,
        contracts_count: contracts,
        employees_count: employees,
        regulations_count: regulations,
        total_count: urgent + contracts + employees + regulations
      }
    end.select { |item| item[:total_count] > 0 }
  end

  def all_pending_items
    urgent_items + pending_contracts + pending_employees + pending_regulations
  end

  def reviewed_this_week_count
    week_start = Time.current.beginning_of_week
    
    Employee.where(reviewed_by_lawyer: true)
            .where('last_lawyer_comment_at >= ?', week_start)
            .count +
    Contract.where(reviewed_by_lawyer: true)
            .where('last_lawyer_comment_at >= ?', week_start)
            .count +
    Regulation.where(reviewed_by_lawyer: true)
              .where('last_lawyer_comment_at >= ?', week_start)
              .count
  end

  def employees_scope
    @company_id ? Employee.where(company_id: @company_id) : Employee.all
  end

  def contracts_scope
    @company_id ? Contract.where(company_id: @company_id) : Contract.all
  end

  def regulations_scope
    @company_id ? Regulation.where(company_id: @company_id) : Regulation.all
  end

  def days_until(date)
    (date - Date.today).to_i
  end

  def time_ago_in_words(time)
    distance_in_days = ((Time.current - time) / 1.day).to_i
    
    if distance_in_days == 0
      "今天"
    elsif distance_in_days == 1
      "1天前"
    else
      "#{distance_in_days}天前"
    end
  end

  # Helper methods for generating paths with company enter action
  def employee_path_with_company(employee)
    Rails.application.routes.url_helpers.enter_lawyer_company_path(
      employee.company,
      redirect_to: Rails.application.routes.url_helpers.employee_path(employee)
    )
  end

  def contract_path_with_company(contract)
    Rails.application.routes.url_helpers.enter_lawyer_company_path(
      contract.company,
      redirect_to: Rails.application.routes.url_helpers.contract_path(contract)
    )
  end

  def regulation_path_with_company(regulation)
    Rails.application.routes.url_helpers.enter_lawyer_company_path(
      regulation.company,
      redirect_to: Rails.application.routes.url_helpers.regulation_path(regulation)
    )
  end
end
