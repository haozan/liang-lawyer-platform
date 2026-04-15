class UnifiedTodoService < ApplicationService
  # accessible_company_ids: 律师可访问的企业 ID 列表，为 nil 时不限制（向后兼容）
  def initialize(company: nil, company_id: nil, user_type: nil, accessible_company_ids: nil)
    @company = company
    @company_id = company_id
    @user_type = user_type # :lawyer or :company
    @accessible_company_ids = accessible_company_ids
  end

  def call
    {
      stats: calculate_stats,
      urgent_items: urgent_items,
      pending_contracts: pending_contracts,
      pending_cases: pending_cases,
      pending_major_issues: pending_major_issues,
      company_todos: (@user_type == :lawyer ? company_todos : nil)
    }.compact
  end

  def stats_for_lawyer(selected_company_id = nil)
    service = self.class.new(company_id: selected_company_id, user_type: :lawyer)
    service.call[:stats]
  end

  def stats_for_company(company)
    service = self.class.new(company: company, user_type: :company)
    service.call[:stats]
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
    
    if @user_type == :lawyer
      # Lawyer view: contracts expiring in 30 days
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
      
      # Cases with upcoming hearings (7 days)
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
      
      # Urgent major issues
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
      
      items.sort_by { |item| item[:record].created_at }
    else
      # Company view
      # Upcoming hearings (7 days)
      @company.cases.not_deleted.where('hearing_at BETWEEN ? AND ?', Time.current, 7.days.from_now).order(:hearing_at).each do |kase|
        days_left = ((kase.hearing_at - Time.current) / 1.day).ceil
        items << {
          type: :case,
          priority: 0,
          record: kase,
          message: "案件《#{kase.name}》#{days_left}天后开庭",
          link: case_path(kase)
        }
      end
      
      # Expired contracts
      @company.contracts.where('end_at < ?', Date.today).order(:end_at).each do |contract|
        items << {
          type: :contract,
          priority: 0,
          record: contract,
          message: "合同《#{contract.name}》已过期，请立即处理",
          link: contract_path(contract)
        }
      end
      
      # Contracts expiring in 7 days
      @company.contracts.where('end_at BETWEEN ? AND ?', Date.today, 7.days.from_now).order(:end_at).each do |contract|
        days_left = (contract.end_at - Date.today).to_i
        items << {
          type: :contract,
          priority: 0,
          record: contract,
          message: "合同《#{contract.name}》#{days_left}天后到期",
          link: contract_path(contract)
        }
      end
      
      # Urgent major issues
      @company.major_issues.not_deleted.where(priority: 'urgent', status: 'pending').each do |issue|
        items << {
          type: :major_issue,
          priority: 0,
          record: issue,
          message: "紧急事项《#{issue.title}》待处理",
          link: major_issue_path(issue)
        }
      end
      
      # Pending reconciliation statements
      cross_month_contracts = @company.contracts.select do |contract|
        contract.cross_month? && !contract.reconciliation_uploaded_this_month?
      end
      cross_month_contracts.each do |contract|
        items << {
          type: :contract,
          priority: 0,
          record: contract,
          message: "合同《#{contract.name}》本月对账单待上传",
          link: contract_path(contract)
        }
      end
      
      items.sort_by { |item| -item[:record].created_at.to_i }
    end
  end

  def pending_contracts
    items = []
    
    if @user_type == :lawyer
      # New contracts (last 30 days)
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
    else
      # Active contracts (last 30 days)
      @company.contracts.where(status: 'active')
                        .where('created_at >= ?', 30.days.ago)
                        .order(created_at: :desc)
                        .limit(10)
                        .each do |contract|
        items << {
          type: :contract,
          priority: 1,
          record: contract,
          message: "合同《#{contract.name}》",
          link: contract_path(contract),
          created_ago: time_ago_in_words(contract.created_at)
        }
      end
    end
    
    items
  end

  def pending_cases
    items = []
    
    base_scope = @user_type == :lawyer ? cases_scope : @company.cases.not_deleted
    
    base_scope.where(status: ['pending', 'investigating', 'in_court'])
              .order(created_at: :desc)
              .limit(10)
              .each do |kase|
      item = {
        type: :case,
        priority: 2,
        record: kase,
        message: "案件《#{kase.name}》- #{status_text(kase.status)}",
        created_ago: time_ago_in_words(kase.created_at)
      }
      
      item[:link] = @user_type == :lawyer ? case_path_with_company(kase) : case_path(kase)
      item[:company] = kase.company if @user_type == :lawyer
      
      items << item
    end
    
    items
  end

  def pending_major_issues
    items = []
    
    base_scope = @user_type == :lawyer ? major_issues_scope : @company.major_issues.not_deleted
    
    base_scope.where(status: ['pending', 'discussing'])
              .order(created_at: :desc)
              .limit(10)
              .each do |issue|
      item = {
        type: :major_issue,
        priority: 2,
        record: issue,
        message: "重大事项《#{issue.title}》",
        created_ago: time_ago_in_words(issue.created_at)
      }
      
      item[:link] = @user_type == :lawyer ? major_issue_path_with_company(issue) : major_issue_path(issue)
      item[:company] = issue.company if @user_type == :lawyer
      
      items << item
    end
    
    items
  end

  def company_todos
    return [] unless @user_type == :lawyer
    
    base = @accessible_company_ids ? Company.where(id: @accessible_company_ids) : Company.all
    companies = @company_id ? base.where(id: @company_id) : base
    
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
    
    if @user_type == :lawyer
      # Count comments created this week by lawyers
      Comment.where('created_at >= ?', week_start)
             .where(author_role: ['lawyer', 'assistant'])
             .count
    else
      # Count comments related to company's records
      Comment.joins("INNER JOIN contracts ON comments.commentable_type = 'Contract' AND comments.commentable_id = contracts.id")
             .where(contracts: { company_id: @company.id })
             .where('comments.created_at >= ?', week_start)
             .count +
      Comment.joins("INNER JOIN cases ON comments.commentable_type = 'Case' AND comments.commentable_id = cases.id")
             .where(cases: { company_id: @company.id })
             .where('comments.created_at >= ?', week_start)
             .count +
      Comment.joins("INNER JOIN major_issues ON comments.commentable_type = 'MajorIssue' AND comments.commentable_id = major_issues.id")
             .where(major_issues: { company_id: @company.id })
             .where('comments.created_at >= ?', week_start)
             .count
    end
  end

  # Scope helpers
  def contracts_scope
    scope = @company_id ? Contract.where(company_id: @company_id) : Contract.all
    # 律师只能看自己负责企业的数据
    scope = scope.where(company_id: @accessible_company_ids) if @accessible_company_ids
    scope
  end

  def cases_scope
    scope = @company_id ? Case.where(company_id: @company_id) : Case.all
    scope = scope.where(company_id: @accessible_company_ids) if @accessible_company_ids
    scope.where(deleted_at: nil)
  end

  def major_issues_scope
    scope = @company_id ? MajorIssue.where(company_id: @company_id) : MajorIssue.all
    scope = scope.where(company_id: @accessible_company_ids) if @accessible_company_ids
    scope.where(deleted_at: nil)
  end

  # Helper methods
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
    when 'pending' then (@user_type == :lawyer ? '待处理' : '待立案')
    when 'investigating' then '调查中'
    when 'in_court' then '庭审中'
    when 'judgement' then '已判决'
    when 'closed' then '已结案'
    else status
    end
  end

  # Path helpers for lawyers - 直接访问合同/案件/重大事项,不需要先进入企业
  def contract_path_with_company(contract)
    Rails.application.routes.url_helpers.contract_path(contract)
  end

  def case_path_with_company(kase)
    Rails.application.routes.url_helpers.case_path(kase)
  end

  def major_issue_path_with_company(issue)
    Rails.application.routes.url_helpers.major_issue_path(issue)
  end

  # Path helpers for company users
  def contract_path(contract)
    Rails.application.routes.url_helpers.contract_path(contract)
  end

  def case_path(kase)
    Rails.application.routes.url_helpers.case_path(kase)
  end

  def major_issue_path(issue)
    Rails.application.routes.url_helpers.major_issue_path(issue)
  end
end
