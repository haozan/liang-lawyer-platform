class CompanyUser < ApplicationRecord
  has_secure_password
  
  # Associations
  belongs_to :company
  
  # Validations
  validates :name, presence: true
  validates :phone, presence: true, uniqueness: { scope: :company_id }, format: { with: /\A1[3-9]\d{9}\z/, message: '必须是有效的中国手机号码' }
  validates :password, length: { minimum: 6 }, allow_nil: true
  validates :role, presence: true, inclusion: { in: %w[employee boss executive] }
  
  # Normalize phone before saving
  before_save :normalize_phone
  
  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :employees, -> { where(role: 'employee') }
  scope :bosses, -> { where(role: 'boss') }
  scope :executives, -> { where(role: 'executive') }
  
  # Display name for comments
  def display_name
    role_text = case role
    when 'employee' then '员工'
    when 'boss' then '企业主'
    when 'executive' then '高管'
    end
    "#{company.name} · #{role_text}"
  end
  
  def boss?
    role == 'boss'
  end
  
  def employee?
    role == 'employee'
  end
  
  def executive?
    role == 'executive'
  end
  
  private
  
  def normalize_phone
    self.phone = phone.to_s.strip if phone.present?
  end
end
