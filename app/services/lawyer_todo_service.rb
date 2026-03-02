class LawyerTodoService < ApplicationService
  def initialize(company_id: nil)
    @company_id = company_id
  end

  def call
    {
      stats: calculate_stats,
      urgent_items: urgent_items,
      pending_contracts: pending_contracts,
      pending_cases: pending_cases,
      pending_major_issues: pending_major_issues,
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
      urgent: urgent_items.count
    }
  end

  def urgent_items
    items = []
    
    # 高优先级：合同即将到期
    contracts_scope.where('end_at BETWEEN ? AND ?', Date.today, 30.days.from_now).each do |contract|
      items << {
        type: :contract,
        priority: 0,
        record: contract,
        company: contract.company,
        message: "合同《#{contract.name}》#{days_until(contract.end_at)}天后到期",
        link: contract_path_with_company(contract)
      }
    end
    
    # 高优先级：案件即将开庭
    cases_scope.where('hearing_at BETWEEN ? AND ?', Time.current, 7.days.from_now).each do |kase|
      items << {
        type: :case,
        priority: 0,
        record: kase,
        company: kase.company,
        message: "案件《#{kase.name}》#{days_until(kase.hearing_at.to_date)}天后开庭",
        link: case_path_with_company(kase)
      }
    end
    
    # 高优先级：紧急重大事项
    major_issues_scope.where(priority: 'urgent', status: 'pending').each do |issue|
      items << {
        type: :major_issue,
        priority: 0,
        record: issue,
        company: issue.company,
        message: "紧急事项《#{issue.title}》待处理",
        link: major_issue_path_with_company(issue)
      }
    end
    
    # 按创建时间排序
    items.sort_by { |item| item[:record].created_at }
  end

  def pending_contracts
    items = []
    
    # 新建合同（最近30天创建的）
    contracts_scope.where('created_at >= ?', 30.days.ago).order(created_at: :desc).limit(10).each do |contract|
      items << {
        type: :contract,
        priority: 1,
        record: contract,
        company: contract.company,
        message: "合同《#{contract.name}》",
        link: contract_path_with_company(contract),
        created_ago: time_ago_in_words(contract.created_at)
      }
    end
    
    items
  end

  def pending_cases
    items = []
    
    # 进行中的案件
    cases_scope.where(status: ['pending', 'investigating', 'in_court']).order(created_at: :desc).limit(10).each do |kase|
      items << {
        type: :case,
        priority: 2,
        record: kase,
        company: kase.company,
        message: "案件《#{kase.name}》- #{status_text(kase.status)}",
        link: case_path_with_company(kase),
        created_ago: time_ago_in_words(kase.created_at)
      }
    end
    
    items
  end

  def pending_major_issues
    items = []
    
    # 待处理的重大事项
    major_issues_scope.where(status: ['pending', 'discussing']).order(created_at: :desc).limit(10).each do |issue|
      items << {
        type: :major_issue,
        priority: 2,
        record: issue,
        company: issue.company,
        message: "重大事项《#{issue.title}》",
        link: major_issue_path_with_company(issue),
        created_ago: time_ago_in_words(issue.created_at)
      }
    end
    
    items
  end

  def company_todos
    companies = @company_id ? Company.where(id: @company_id) : Company.all
    
    companies.map do |company|
      urgent = urgent_items.select { |item| item[:company].id == company.id }.count
      contracts = pending_contracts.select { |item| item[:company].id == company.id }.count
      cases = pending_cases.select { |item| item[:company].id == company.id }.count
      issues = pending_major_issues.select { |item| item[:company].id == company.id }.count
      
      {
        company: company,
        urgent_count: urgent,
        contracts_count: contracts,
        cases_count: cases,
        issues_count: issues,
        total_count: urgent + contracts + cases + issues
      }
    end.select { |item| item[:total_count] > 0 }
  end

  def all_pending_items
    urgent_items + pending_contracts + pending_cases + pending_major_issues
  end

  def reviewed_this_week_count
    week_start = Time.current.beginning_of_week
    
    # Count comments created this week by lawyers
    Comment.where('created_at >= ?', week_start)
           .where(author_role: ['lawyer', 'assistant'])
           .count
  end

  def contracts_scope
    @company_id ? Contract.where(company_id: @company_id) : Contract.all
  end

  def cases_scope
    scope = @company_id ? Case.where(company_id: @company_id) : Case.all
    scope.where(deleted_at: nil)
  end

  def major_issues_scope
    scope = @company_id ? MajorIssue.where(company_id: @company_id) : MajorIssue.all
    scope.where(deleted_at: nil)
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

  def status_text(status)
    case status
    when 'pending' then '待处理'
    when 'investigating' then '调查中'
    when 'in_court' then '庭审中'
    when 'judgement' then '已判决'
    when 'closed' then '已结案'
    else status
    end
  end

  # Helper methods for generating paths with company enter action
  def contract_path_with_company(contract)
    Rails.application.routes.url_helpers.enter_lawyer_company_path(
      contract.company,
      redirect_to: Rails.application.routes.url_helpers.contract_path(contract)
    )
  end

  def case_path_with_company(kase)
    Rails.application.routes.url_helpers.enter_lawyer_company_path(
      kase.company,
      redirect_to: Rails.application.routes.url_helpers.case_path(kase)
    )
  end

  def major_issue_path_with_company(issue)
    Rails.application.routes.url_helpers.enter_lawyer_company_path(
      issue.company,
      redirect_to: Rails.application.routes.url_helpers.major_issue_path(issue)
    )
  end
end
