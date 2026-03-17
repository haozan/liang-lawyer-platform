class Company < ApplicationRecord
  # Associations
  has_many :company_users, dependent: :destroy
  has_many :contracts, dependent: :destroy
  has_many :cases, dependent: :destroy
  has_many :major_issues, dependent: :destroy
  has_many :contract_tags, dependent: :destroy
  belongs_to :suspended_by, class_name: 'LawyerAccount', optional: true
  
  # Team associations
  belongs_to :lawyer_team, optional: true
  has_many :company_team_accesses, dependent: :destroy
  has_many :accessible_teams, through: :company_team_accesses, source: :lawyer_team
  
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[active suspended archived] }
  
  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :active, -> { where(status: 'active') }
  scope :suspended, -> { where(status: 'suspended') }
  scope :archived, -> { where(status: 'archived') }
  scope :expires_soon, ->(days = 30) { 
    where('service_expires_at IS NOT NULL AND service_expires_at <= ?', Date.today + days.days)
      .where(status: 'active')
  }
  scope :expired, -> {
    where('service_expires_at IS NOT NULL AND service_expires_at < ?', Date.today)
      .where(status: 'active')
  }
  
  # Team access scopes
  scope :accessible_by_team, ->(team) {
    return none unless team
    
    left_joins(:company_team_accesses)
      .where('companies.lawyer_team_id = ? OR company_team_accesses.lawyer_team_id = ?', team.id, team.id)
      .where('company_team_accesses.id IS NULL OR company_team_accesses.expires_at IS NULL OR company_team_accesses.expires_at > ?', Time.current)
      .select('DISTINCT companies.*')
  }
  
  scope :accessible_by_lawyer, ->(lawyer) {
    return none unless lawyer&.lawyer_team_id
    accessible_by_team(lawyer.lawyer_team)
  }
  
  # Team access methods
  def accessible_by_team?(team)
    return false unless team
    lawyer_team_id == team.id || accessible_teams.active.exists?(id: team.id)
  end
  
  def accessible_by_lawyer?(lawyer)
    return false unless lawyer&.lawyer_team
    accessible_by_team?(lawyer.lawyer_team)
  end
  
  def accessible_team_ids
    ids = [lawyer_team_id].compact
    ids += company_team_accesses.active.pluck(:lawyer_team_id)
    ids.uniq
  end
  
  def primary_team
    lawyer_team
  end
  
  def grant_access_to_team(team:, access_level: 'viewer', authorized_by:, expires_at: nil, notes: nil)
    return false if team.id == lawyer_team_id
    
    company_team_accesses.create(
      lawyer_team_id: team.id,
      access_level: access_level,
      authorized_by: authorized_by,
      authorized_at: Time.current,
      expires_at: expires_at,
      notes: notes
    )
  end
  
  def revoke_access_from_team(team)
    company_team_accesses.where(lawyer_team_id: team.id).destroy_all
  end
  
  # Permission check methods
  # 超级管理员：完全权限（增删改查所有企业）
  # 团队负责人：管理本团队主责的企业（修改/删除/授权协作团队）
  # 普通律师：只能查看和使用企业，不能修改/删除
  
  def can_be_managed_by?(lawyer)
    return false unless lawyer
    return true if lawyer.super_admin?
    return true if lawyer.team_leader_of?(lawyer_team)
    false
  end
  
  def can_be_deleted_by?(lawyer)
    return false unless lawyer
    return true if lawyer.super_admin?
    return true if lawyer.team_leader_of?(lawyer_team)
    false
  end
  
  def can_be_created_by?(lawyer)
    return false unless lawyer
    return true if lawyer.super_admin?
    return true if lawyer.team_leader?
    false
  end
  
  # 检查是否可以安全删除（没有关联数据）
  def safe_to_delete?
    contracts.none? && 
    cases.not_deleted.none? && 
    major_issues.not_deleted.none? && 
    company_users.none?
  end
  
  # 获取关联数据统计（用于删除确认提示）
  def associated_data_summary
    {
      contracts_count: contracts.count,
      cases_count: cases.not_deleted.count,
      major_issues_count: major_issues.not_deleted.count,
      company_users_count: company_users.count
    }
  end
  
  # Status check methods
  def active?
    status == 'active'
  end
  
  def suspended?
    status == 'suspended'
  end
  
  def archived?
    status == 'archived'
  end
  
  def service_expired?
    service_expires_at.present? && service_expires_at < Date.today
  end
  
  def service_expires_soon?(days = 30)
    service_expires_at.present? && 
    service_expires_at >= Date.today && 
    service_expires_at <= Date.today + days.days
  end
  
  def days_until_expiry
    return nil unless service_expires_at.present?
    (service_expires_at - Date.today).to_i
  end
  
  # Service management methods
  def suspend!(reason:, suspended_by_lawyer:)
    update!(
      status: 'suspended',
      suspended_at: Time.current,
      suspended_reason: reason,
      suspended_by_id: suspended_by_lawyer.id
    )
  end
  
  def resume!(service_expires_at: nil)
    updates = { 
      status: 'active', 
      suspended_at: nil, 
      suspended_reason: nil,
      suspended_by_id: nil
    }
    updates[:service_expires_at] = service_expires_at if service_expires_at.present?
    update!(updates)
  end
  
  def archive!
    update!(status: 'archived')
  end
  
  def can_use_service?
    active? && !service_expired?
  end
  
  # Status display
  def status_text
    case status
    when 'active'
      if service_expired?
        '已到期'
      elsif service_expires_soon?
        '即将到期'
      else
        '正常服务'
      end
    when 'suspended'
      '暂停服务'
    when 'archived'
      '已归档'
    else
      '未知状态'
    end
  end
  
  def status_badge_class
    case status
    when 'active'
      if service_expired?
        'badge-danger'
      elsif service_expires_soon?
        'badge-warning'
      else
        'badge-success'
      end
    when 'suspended'
      'badge-secondary'
    when 'archived'
      'badge-secondary'
    else
      'badge-secondary'
    end
  end
end
