class Company < ApplicationRecord
  # Associations
  has_many :company_memberships, dependent: :destroy
  has_many :company_users, through: :company_memberships
  has_many :contracts, dependent: :destroy
  has_many :cases, dependent: :destroy
  has_many :major_issues, dependent: :destroy
  has_many :contract_tags, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[active suspended archived] }

  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  # 律师只能访问自己负责的企业（assigned_lawyer_ids 包含该律师）
  scope :accessible_by_lawyer, ->(lawyer) {
    where('? = ANY(assigned_lawyer_ids)', lawyer.id)
  }
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

  # 负责律师（多人）
  def assigned_lawyers
    return LawyerAccount.none if assigned_lawyer_ids.blank?
    LawyerAccount.where(id: assigned_lawyer_ids)
  end

  # Permission check methods（简化：所有律师都可管理，无团队区别）
  def can_be_managed_by?(lawyer)
    lawyer.present?
  end

  def can_be_deleted_by?(lawyer)
    lawyer.present?
  end

  def can_be_created_by?(lawyer)
    lawyer.present?
  end

  # 检查是否可以安全删除（没有关联数据）
  def safe_to_delete?
    contracts.none? &&
      cases.not_deleted.none? &&
      major_issues.not_deleted.none? &&
      company_memberships.none?
  end

  # 获取关联数据统计（用于删除确认提示）
  def associated_data_summary
    {
      contracts_count: contracts.count,
      cases_count: cases.not_deleted.count,
      major_issues_count: major_issues.not_deleted.count,
      members_count: company_memberships.count
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
  def suspend!(reason:, suspended_by_lawyer: nil)
    update!(
      status: 'suspended',
      suspended_at: Time.current,
      suspended_reason: reason
    )
  end

  def resume!(service_expires_at: nil)
    updates = {
      status: 'active',
      suspended_at: nil,
      suspended_reason: nil
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
    when 'suspended' then '暂停服务'
    when 'archived'  then '已归档'
    else '未知状态'
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
    when 'suspended', 'archived' then 'badge-secondary'
    else 'badge-secondary'
    end
  end
end
