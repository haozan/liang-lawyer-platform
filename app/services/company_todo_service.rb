class CompanyTodoService < ApplicationService
  def initialize(company:)
    @company = company
  end

  def call
    {
      stats: calculate_stats,
      urgent_items: urgent_items,
      pending_contracts: pending_contracts,
      pending_cases: pending_cases,
      pending_major_issues: pending_major_issues
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
    
    # 高优先级：即将开庭的案件
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
    
    # 高优先级：已过期的业务合同
    @company.contracts.where('end_at < ?', Date.today).order(:end_at).each do |contract|
      items << {
        type: :contract,
        priority: 0,
        record: contract,
        message: "合同《#{contract.name}》已过期，请立即处理",
        link: contract_path(contract)
      }
    end
    
    # 高优先级：7天内到期的合同
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
    
    # 高优先级：紧急重大事项
    @company.major_issues.not_deleted.where(priority: 'urgent', status: 'pending').each do |issue|
      items << {
        type: :major_issue,
        priority: 0,
        record: issue,
        message: "紧急事项《#{issue.title}》待处理",
        link: major_issue_path(issue)
      }
    end
    
    # 高优先级：待上传对账单的合同
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
    
    # 按创建时间排序
    items.sort_by { |item| -item[:record].created_at.to_i }
  end

  def pending_contracts
    items = []
    
    # 执行中的合同（最近30天创建的）
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
    
    items
  end

  def pending_cases
    items = []
    
    # 进行中的案件
    @company.cases.not_deleted
                  .where(status: ['pending', 'investigating', 'in_court'])
                  .order(created_at: :desc)
                  .limit(10)
                  .each do |kase|
      items << {
        type: :case,
        priority: 2,
        record: kase,
        message: "案件《#{kase.name}》- #{status_text(kase.status)}",
        link: case_path(kase),
        created_ago: time_ago_in_words(kase.created_at)
      }
    end
    
    items
  end

  def pending_major_issues
    items = []
    
    # 待处理的重大事项
    @company.major_issues.not_deleted
                         .where(status: ['pending', 'discussing'])
                         .order(created_at: :desc)
                         .limit(10)
                         .each do |issue|
      items << {
        type: :major_issue,
        priority: 2,
        record: issue,
        message: "重大事项《#{issue.title}》",
        link: major_issue_path(issue),
        created_ago: time_ago_in_words(issue.created_at)
      }
    end
    
    items
  end

  def all_pending_items
    urgent_items + pending_contracts + pending_cases + pending_major_issues
  end

  def reviewed_this_week_count
    week_start = Time.current.beginning_of_week
    
    # 统计本周创建的评论数
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
    when 'pending' then '待立案'
    when 'investigating' then '调查中'
    when 'in_court' then '庭审中'
    when 'judgement' then '已判决'
    when 'closed' then '已结案'
    else status
    end
  end

  # Helper methods for generating paths
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
