class AnnouncementService < ApplicationService
  # 缓存有效期（分钟）
  CACHE_TTL = 5.minutes

  attr_reader :user, :company_ids

  def initialize(user:, company_ids: nil)
    @user = user
    @company_ids = company_ids || (user.is_a?(CompanyUser) ? [user.company_id] : Company.pluck(:id))
  end

  def call
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      {
        manual_announcements: fetch_manual_announcements,
        system_announcements: generate_system_announcements,
        combined_announcements: combine_and_sort_announcements,
        grouped_announcements: group_announcements,
        stats: calculate_stats
      }
    end
  end

  # 主动失效当前用户的公告缓存（数据变更时调用）
  def self.expire_cache_for(user)
    cache_key = "announcements/#{user.class.name.underscore}/#{user.id}"
    Rails.cache.delete(cache_key)
  end
  
  private

  # 基于用户类型和ID生成唯一缓存键
  def cache_key
    "announcements/#{user.class.name.underscore}/#{user.id}"
  end

  # 获取手动创建的公告（从数据库）
  def fetch_manual_announcements
    Announcement.active
      .for_company(@company_ids)
      .where(created_by_type: 'LawyerAccount')
      .ordered
      .limit(20)
      .map { |announcement| format_manual_announcement(announcement) }
  end
  
  # 生成系统自动公告（动态生成，不存数据库）
  def generate_system_announcements
    announcements = []
    
    # 1. 开庭提醒（15天内）
    announcements += generate_hearing_announcements
    
    # 2. 合同到期提醒（15天内）
    announcements += generate_contract_expiry_announcements
    
    # 3. 待审查合同
    announcements += generate_contract_review_announcements
    
    # 4. 待答复重大事项（仅律师）
    if @user.is_a?(LawyerAccount)
      announcements += generate_major_issue_review_announcements
    end
    
    # 5. 对账单相关公告（根据用户类型生成不同公告）
    if @user.is_a?(CompanyUser)
      announcements += generate_reconciliation_upload_announcements
    elsif @user.is_a?(LawyerAccount)
      announcements += generate_reconciliation_review_announcements
    end
    
    # 5. 待领取判决书
    announcements += generate_judgement_collection_announcements
    
    # 6. 财产保全到期提醒（30天内）
    announcements += generate_property_preservation_announcements
    
    # 过滤已消除的公告
    announcements = filter_dismissed_announcements(announcements)
    
    # 按分组优先级、紧急程度排序
    announcements.sort_by { |a| [-group_priority(a[:announcement_type]), -priority_score(a[:priority]), -a[:urgency_score]] }
  end
  
  # 合并手动公告和系统公告，按优先级排序
  def combine_and_sort_announcements
    all = fetch_manual_announcements + generate_system_announcements
    all.sort_by { |a| [-group_priority(a[:announcement_type]), -priority_score(a[:priority]), -a[:urgency_score]] }.take(50)
  end
  
  # 按分组组织公告
  def group_announcements
    all_announcements = combine_and_sort_announcements
    groups = AnnouncementGroup.ordered.to_a
    
    groups.map do |group|
      announcements_in_group = all_announcements.select do |announcement|
        AnnouncementGroup.group_for_type(announcement[:announcement_type])&.id == group.id
      end
      
      {
        group: group,
        announcements: announcements_in_group,
        count: announcements_in_group.count
      }
    end.reject { |g| g[:count].zero? }
  end
  
  # 计算统计数据
  def calculate_stats
    all_announcements = combine_and_sort_announcements
    
    stats_by_group = {}
    AnnouncementGroup.all.each do |group|
      count = all_announcements.count do |announcement|
        AnnouncementGroup.group_for_type(announcement[:announcement_type])&.id == group.id
      end
      stats_by_group[group.group_key.to_sym] = count
    end
    
    {
      total: all_announcements.count,
      urgent: all_announcements.count { |a| a[:priority] == 'urgent' },
      important: all_announcements.count { |a| a[:priority] == 'important' },
      normal: all_announcements.count { |a| a[:priority] == 'normal' },
      by_group: stats_by_group
    }
  end
  
  # 开庭提醒
  def generate_hearing_announcements
    cases = Case.not_deleted
      .where(company_id: @company_ids)
      .where('hearing_at BETWEEN ? AND ?', Time.current, 15.days.from_now)
      .order(:hearing_at)
      .limit(10)
    
    cases.map do |case_record|
      days_left = ((case_record.hearing_at - Time.current) / 1.day).ceil
      priority = days_left <= 3 ? 'urgent' : days_left <= 7 ? 'important' : 'normal'
      urgency_score = 100 - days_left
      
      {
        id: "hearing_#{case_record.id}",
        type: 'system',
        announcement_type: 'hearing',
        priority: priority,
        urgency_score: urgency_score,
        title: "案件「#{case_record.name}」将于#{days_left}天后开庭",
        content: "开庭时间：#{case_record.hearing_at.strftime('%Y-%m-%d %H:%M')}",
        link: case_path_helper(case_record),
        published_at: Time.current,
        icon: 'gavel',
        related: case_record
      }
    end
  end
  
  # 合同到期提醒
  def generate_contract_expiry_announcements
    contracts = Contract.where(company_id: @company_ids)
      .where('end_at BETWEEN ? AND ?', Date.today, 15.days.from_now)
      .order(:end_at)
      .limit(10)
    
    contracts.map do |contract|
      days_left = (contract.end_at - Date.today).to_i
      priority = days_left <= 3 ? 'urgent' : days_left <= 7 ? 'important' : 'normal'
      urgency_score = 90 - days_left
      
      {
        id: "contract_expiry_#{contract.id}",
        type: 'system',
        announcement_type: 'contract_expiry',
        priority: priority,
        urgency_score: urgency_score,
        title: "合同「#{contract.name}」将于#{days_left}天后到期",
        content: "到期日期：#{contract.end_at.strftime('%Y-%m-%d')}",
        link: contract_path_helper(contract),
        published_at: Time.current,
        icon: 'file-text',
        related: contract
      }
    end
  end
  
  # 待审查合同
  def generate_contract_review_announcements
    contracts = Contract.where(company_id: @company_ids)
      .pending_lawyer_review
      .order(created_at: :desc)
      .limit(5)
    
    contracts.map do |contract|
      overdue_days = contract.overdue_days
      priority = overdue_days > 5 ? 'urgent' : overdue_days > 2 ? 'important' : 'normal'
      urgency_score = 80 + overdue_days
      
      {
        id: "contract_review_#{contract.id}",
        type: 'system',
        announcement_type: 'contract_review',
        priority: priority,
        urgency_score: urgency_score,
        title: "合同「#{contract.name}」待律师审查",
        content: overdue_days > 0 ? "已逾期#{overdue_days}天" : "上传于#{contract.created_at.strftime('%Y-%m-%d')}",
        link: contract_path_helper(contract),
        published_at: Time.current,
        icon: 'file-check',
        related: contract
      }
    end
  end
  
  # 待答复重大事项（律师视角）
  def generate_major_issue_review_announcements
    major_issues = MajorIssue.where(company_id: @company_ids)
      .not_deleted
      .pending_lawyer_review
      .order(created_at: :desc)
      .limit(5)
    
    major_issues.map do |issue|
      overdue_days = issue.review_overdue_days
      priority = overdue_days > 5 ? 'urgent' : overdue_days > 2 ? 'important' : 'normal'
      urgency_score = 75 + overdue_days
      
      {
        id: "major_issue_review_#{issue.id}",
        type: 'system',
        announcement_type: 'major_issue_review',
        priority: priority,
        urgency_score: urgency_score,
        title: "重大事项「#{issue.title}」待律师答复",
        content: overdue_days > 0 ? "已逾期#{overdue_days}天" : "创建于#{issue.created_at.strftime('%Y-%m-%d')}",
        link: major_issue_path_helper(issue),
        published_at: Time.current,
        icon: 'message-square',
        related: issue
      }
    end
  end
  
  # 待上传对账单（企业主视角）
  def generate_reconciliation_upload_announcements
    contracts = Contract.where(company_id: @company_ids, status: 'active')
      .select { |c| c.cross_month? && c.reconciliation_overdue? }
      .take(5)
    
    contracts.map do |contract|
      {
        id: "reconciliation_upload_pending_#{contract.id}",
        type: 'system',
        announcement_type: 'reconciliation_upload_pending',
        priority: 'important',
        urgency_score: 70,
        title: "合同「#{contract.name}」本月对账单待上传",
        content: "当前月份：#{Date.today.strftime('%Y年%m月')}",
        link: contract_path_helper(contract),
        published_at: Time.current,
        icon: 'file-plus',
        related: contract
      }
    end
  end
  
  # 待审查对账单（律师视角）
  def generate_reconciliation_review_announcements
    reconciliations = Reconciliation.joins(:contract)
      .where(contracts: { company_id: @company_ids })
      .pending_lawyer_review
      .order(uploaded_at: :desc)
      .limit(5)
    
    reconciliations.map do |reconciliation|
      overdue_days = reconciliation.review_overdue_days
      priority = overdue_days > 5 ? 'urgent' : overdue_days > 2 ? 'important' : 'normal'
      urgency_score = 70 + overdue_days
      
      {
        id: "reconciliation_review_pending_#{reconciliation.id}",
        type: 'system',
        announcement_type: 'reconciliation_review_pending',
        priority: priority,
        urgency_score: urgency_score,
        title: "对账单「#{reconciliation.contract.name} - #{reconciliation.period_display}」待审查",
        content: overdue_days > 0 ? "已逾期#{overdue_days}天" : "上传于#{reconciliation.uploaded_at.strftime('%Y-%m-%d')}",
        link: contract_path_helper(reconciliation.contract),
        published_at: Time.current,
        icon: 'file-check',
        related: reconciliation
      }
    end
  end
  
  # 待领取判决书
  def generate_judgement_collection_announcements
    cases = Case.not_deleted
      .where(company_id: @company_ids)
      .where(status: 'in_court')
      .where('hearing_at < ?', Time.current)
      .where('judgement_received_at IS NULL')
      .order(hearing_at: :desc)
      .limit(5)
    
    cases.map do |case_record|
      days_since_hearing = ((Time.current - case_record.hearing_at) / 1.day).ceil
      priority = days_since_hearing > 45 ? 'urgent' : days_since_hearing > 30 ? 'important' : 'normal'
      urgency_score = 60 + days_since_hearing
      
      {
        id: "judgement_collection_#{case_record.id}",
        type: 'system',
        announcement_type: 'judgement_collection',
        priority: priority,
        urgency_score: urgency_score,
        title: "案件「#{case_record.name}」判决书待领取",
        content: "开庭已#{days_since_hearing}天，尚未收取判决书",
        link: case_path_helper(case_record),
        published_at: Time.current,
        icon: 'file-badge',
        related: case_record
      }
    end
  end
  
  # 财产保全到期提醒（37天内）
  def generate_property_preservation_announcements
    cases = Case.not_deleted
      .where(company_id: @company_ids)
      .where('property_preservation_deadline BETWEEN ? AND ?', Date.current, 37.days.from_now)
      .order(:property_preservation_deadline)
      .limit(10)
    
    cases.map do |case_record|
      days_left = case_record.property_preservation_days_left
      
      # 检查是否已消除提醒（任意用户消除即视为已处理）
      is_dismissed = @user ? AnnouncementDismissal.dismissed_by_user?('property_preservation', case_record, @user) : false
      
      # 渐进式优先级逻辑：
      # - 已消除：按剩余天数设置（不升级）
      # - 未消除 + ≤14天：普通
      # - 未消除 + ≤14天：重要（重点提示）
      # - 未消除 + ≤7天：紧急（重点提示）
      if is_dismissed
        # 已消除，但仍需按剩余天数提醒
        priority = days_left <= 3 ? 'urgent' : days_left <= 7 ? 'important' : 'normal'
      else
        # 未消除，执行渐进式优先级
        if days_left <= 7
          priority = 'urgent'  # 7天内且未处理 → 紧急
        elsif days_left <= 14
          priority = 'important'  # 14天内且未处理 → 重要
        else
          priority = 'normal'  # 37天内 → 普通
        end
      end
      
      urgency_score = 95 - days_left # 比开庭提醒略低，但仍然很重要
      
      {
        id: "property_preservation_#{case_record.id}",
        type: 'system',
        announcement_type: 'property_preservation',
        priority: priority,
        urgency_score: urgency_score,
        title: "案件「#{case_record.name}」财产保全将于#{days_left}天后到期",
        content: "到期日期：#{case_record.property_preservation_deadline.strftime('%Y年%m月%d日')}，请及时续保或解除",
        link: case_path_helper(case_record),
        published_at: Time.current,
        icon: 'shield-alert',
        related: case_record
      }
    end
  end
  
  # 格式化手动公告
  def format_manual_announcement(announcement)
    {
      id: "manual_#{announcement.id}",
      type: 'manual',
      announcement_type: announcement.announcement_type,
      priority: announcement.priority,
      urgency_score: priority_score(announcement.priority) * 10,
      title: announcement.title,
      content: announcement.content,
      link: announcement.related ? polymorphic_path_helper(announcement.related) : nil,
      published_at: announcement.published_at,
      icon: icon_for_type(announcement.announcement_type),
      related: announcement.related,
      read: @user ? announcement.read_by?(@user) : false,
      announcement_record: announcement
    }
  end
  
  # 过滤已消除的公告
  def filter_dismissed_announcements(announcements)
    return announcements unless @user
    
    announcements.reject do |announcement|
      next false unless announcement[:related]
      AnnouncementDismissal.dismissed_by_user?(
        announcement[:announcement_type],
        announcement[:related],
        @user
      )
    end
  end
  
  # 获取分组优先级
  def group_priority(announcement_type)
    group = AnnouncementGroup.group_for_type(announcement_type)
    group ? group.priority : 0
  end
  
  def priority_score(priority)
    case priority
    when 'urgent' then 3
    when 'important' then 2
    when 'normal' then 1
    else 0
    end
  end
  
  def icon_for_type(type)
    case type
    when 'hearing' then 'gavel'
    when 'contract_expiry' then 'file-text'
    when 'contract_review' then 'file-check'
    when 'major_issue_review' then 'message-square'
    when 'reconciliation_upload_pending' then 'file-plus'
    when 'reconciliation_review_pending' then 'file-check'
    when 'reconciliation_overdue' then 'file-plus'  # 向后兼容
    when 'judgement_collection' then 'file-badge'
    when 'property_preservation' then 'shield-alert'
    when 'custom' then 'bell'
    else 'info'
    end
  end
  
  def contract_path_helper(contract)
    Rails.application.routes.url_helpers.contract_path(contract)
  end
  
  def case_path_helper(case_record)
    Rails.application.routes.url_helpers.case_path(case_record)
  end
  
  def major_issue_path_helper(major_issue)
    Rails.application.routes.url_helpers.major_issue_path(major_issue)
  end
  
  def polymorphic_path_helper(record)
    case record
    when Contract then Rails.application.routes.url_helpers.contract_path(record)
    when Case then Rails.application.routes.url_helpers.case_path(record)
    when MajorIssue then Rails.application.routes.url_helpers.major_issue_path(record)
    when Reconciliation then Rails.application.routes.url_helpers.contract_path(record.contract_id)
    else "#"
    end
  end
end
