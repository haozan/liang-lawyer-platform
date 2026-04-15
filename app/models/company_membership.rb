class CompanyMembership < ApplicationRecord
  # Associations
  belongs_to :company
  belongs_to :company_user

  # Validations
  validates :company_id, presence: true
  validates :company_user_id, presence: true,
            uniqueness: { scope: :company_id, message: '该成员已在此企业中' }
  validates :role, presence: true, inclusion: { in: %w[boss employee] }

  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :bosses,    -> { where(role: 'boss') }
  scope :employees, -> { where(role: 'employee') }

  # Role display
  def role_display
    case role
    when 'boss'     then '老板'
    when 'employee' then '员工'
    else role
    end
  end

  def boss?
    role == 'boss'
  end

  def employee?
    role == 'employee'
  end
end
