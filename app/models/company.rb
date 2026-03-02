class Company < ApplicationRecord
  # Associations
  has_many :company_users, dependent: :destroy
  has_many :contracts, dependent: :destroy
  has_many :cases, dependent: :destroy
  has_many :major_issues, dependent: :destroy
  belongs_to :suspended_by, class_name: 'LawyerAccount', optional: true
  
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
