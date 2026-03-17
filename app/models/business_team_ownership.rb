class BusinessTeamOwnership < ApplicationRecord
  # Polymorphic association to business (Contract, Case, MajorIssue)
  belongs_to :business, polymorphic: true, optional: true
  
  # Associations
  belongs_to :lawyer_team
  belongs_to :company
  belongs_to :authorized_by, class_name: 'LawyerAccount', optional: true
  
  # Validations
  validates :business_type, presence: true, inclusion: { in: %w[Contract Case MajorIssue] }
  validates :business_id, presence: true
  validates :lawyer_team_id, presence: true
  validates :company_id, presence: true
  validates :access_level, presence: true, inclusion: { in: %w[owner collaborator viewer] }
  validates :lawyer_team_id, uniqueness: { scope: [:business_type, :business_id], message: '该团队已经拥有此业务的权限' }
  
  # Scopes
  scope :primary, -> { where(is_primary: true) }
  scope :collaborators, -> { where(is_primary: false) }
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at IS NOT NULL AND expires_at <= ?', Time.current) }
  scope :for_team, ->(team_id) { where(lawyer_team_id: team_id) }
  scope :for_business, ->(type, id) { where(business_type: type, business_id: id) }
  
  # Callbacks
  before_create :set_authorized_at
  
  # Access level display
  def access_level_display
    case access_level
    when 'owner' then '所有者'
    when 'collaborator' then '协作者'
    when 'viewer' then '查看者'
    end
  end
  
  # Check if ownership is expired
  def expired?
    expires_at.present? && expires_at <= Time.current
  end
  
  # Check if ownership is active
  def active?
    !expired?
  end
  
  private
  
  def set_authorized_at
    self.authorized_at ||= Time.current
  end
end
