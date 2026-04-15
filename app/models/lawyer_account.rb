class LawyerAccount < ApplicationRecord
  has_secure_password

  # Concerns
  include LockableAccount

  # Associations
  has_many :mentioned_issues, class_name: 'MajorIssue', foreign_key: 'mentioned_lawyer_id'
  has_many :case_team_members, dependent: :destroy
  has_many :cases, through: :case_team_members
  has_many :case_filters, as: :user, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :phone, presence: true, uniqueness: true,
            format: { with: /\A1[3-9]\d{9}\z/, message: '必须是有效的中国手机号码' }
  validates :password, length: { minimum: 6 }, allow_nil: true
  validates :role, presence: true, inclusion: { in: %w[assistant lawyer admin] }

  # Normalize phone before saving
  before_save :normalize_phone

  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :lawyers, -> { where(role: %w[lawyer admin]) }
  scope :assistants, -> { where(role: 'assistant') }

  # 负责的企业（通过 assigned_lawyer_ids array 查询）
  def assigned_companies
    Company.where('? = ANY(assigned_lawyer_ids)', id)
  end

  # Role checking methods
  def lawyer?
    role.in?(%w[lawyer admin])
  end

  def assistant?
    role == 'assistant'
  end

  def admin?
    role == 'admin'
  end

  # 兼容旧代码 super_admin?
  alias_method :super_admin?, :admin?

  # Display name for comments
  def display_name
    "#{name}（#{role_display}）"
  end

  # Role display
  def role_display
    case role
    when 'admin'     then '管理员'
    when 'lawyer'    then '律师'
    when 'assistant' then '律师助理'
    else role
    end
  end

  private

  def normalize_phone
    self.phone = phone.to_s.strip if phone.present?
  end
end
