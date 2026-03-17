class LawyerBusinessAccess < ApplicationRecord
  # Polymorphic association to business
  belongs_to :business, polymorphic: true, optional: true
  
  # Associations
  belongs_to :lawyer, class_name: 'LawyerAccount', foreign_key: 'lawyer_id'
  belongs_to :authorized_by, class_name: 'LawyerAccount', optional: true
  
  # Validations
  validates :lawyer_id, presence: true
  validates :business_type, presence: true, inclusion: { in: %w[Contract Case MajorIssue] }
  validates :business_id, presence: true
  validates :access_level, presence: true, inclusion: { in: %w[viewer collaborator] }
  validates :reason, presence: true
  validates :lawyer_id, uniqueness: { scope: [:business_type, :business_id], message: '该律师已经拥有此业务的权限' }
  
  # Scopes
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at IS NOT NULL AND expires_at <= ?', Time.current) }
  scope :for_lawyer, ->(lawyer_id) { where(lawyer_id: lawyer_id) }
  scope :for_business, ->(type, id) { where(business_type: type, business_id: id) }
  scope :expiring_soon, -> { where('expires_at IS NOT NULL AND expires_at > ? AND expires_at <= ?', Time.current, 7.days.from_now) }
  
  # Access level display
  def access_level_display
    case access_level
    when 'viewer' then '查看者'
    when 'collaborator' then '协作者'
    end
  end
  
  # Check if access is expired
  def expired?
    expires_at.present? && expires_at <= Time.current
  end
  
  # Check if access is active
  def active?
    !expired?
  end
  
  # Days until expiration
  def days_until_expiration
    return nil unless expires_at.present?
    ((expires_at - Time.current) / 1.day).to_i
  end
end
