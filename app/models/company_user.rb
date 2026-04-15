class CompanyUser < ApplicationRecord
  has_secure_password

  # Concerns
  include LockableAccount

  # Associations
  has_many :company_memberships, dependent: :destroy
  has_many :companies, through: :company_memberships
  has_many :case_filters, as: :user, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :phone, presence: true, uniqueness: true,
            format: { with: /\A1[3-9]\d{9}\z/, message: '必须是有效的中国手机号码' }
  validates :password, length: { minimum: 6 }, allow_nil: true

  # Normalize phone before saving
  before_save :normalize_phone

  # Scopes
  scope :ordered, -> { order(created_at: :desc) }

  # 获取在指定企业中的角色
  def role_in(company)
    company_memberships.find_by(company: company)&.role
  end

  # 是否是指定企业的老板
  def boss_in?(company)
    role_in(company) == 'boss'
  end

  # 是否是指定企业的员工
  def employee_in?(company)
    role_in(company) == 'employee'
  end

  # 兼容旧代码中直接用 .boss? .employee? 的地方（需要有 current_company 上下文）
  def boss?
    # 用于兼容：在有上下文的地方请用 boss_in?(company)
    false
  end

  def employee?
    false
  end

  # Display name（需要企业上下文时用 display_name_in）
  def display_name
    name
  end

  def display_name_in(company)
    membership = company_memberships.find_by(company: company)
    role_text = membership ? membership.role_display : '成员'
    "#{company.name} · #{name}（#{role_text}）"
  end

  # 判断企业用户是否可以管理附件（在指定企业中是老板）
  def can_manage_attachments_in?(company)
    boss_in?(company)
  end

  private

  def normalize_phone
    self.phone = phone.to_s.strip if phone.present?
  end
end
