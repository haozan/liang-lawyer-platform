class CompanyTeamAccess < ApplicationRecord
  # Associations
  belongs_to :company
  belongs_to :lawyer_team
  belongs_to :authorized_by, class_name: 'LawyerAccount', optional: true
  
  # Validations
  validates :company_id, presence: true
  validates :lawyer_team_id, presence: true, uniqueness: { scope: :company_id, message: "该团队已被授权访问此企业" }
  validates :access_level, presence: true, inclusion: { in: %w[viewer editor manager], message: "权限级别必须是 viewer, editor 或 manager" }
  
  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at IS NOT NULL AND expires_at <= ?', Time.current) }
  
  # Callbacks
  before_create :set_authorized_at
  
  # Access level display
  def access_level_text
    case access_level
    when 'viewer' then '查看者'
    when 'editor' then '编辑者'
    when 'manager' then '管理者'
    else access_level
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
  
  private
  
  def set_authorized_at
    self.authorized_at ||= Time.current
  end
end
