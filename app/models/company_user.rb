class CompanyUser < ApplicationRecord
  has_secure_password
  
  # Associations
  belongs_to :company
  
  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: { scope: :company_id }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, allow_nil: true
  validates :role, presence: true, inclusion: { in: %w[hr contract boss] }
  
  # Normalize email before saving
  before_save :normalize_email
  
  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :hr_users, -> { where(role: 'hr') }
  scope :contract_users, -> { where(role: 'contract') }
  scope :boss_users, -> { where(role: 'boss') }
  
  # Display name for comments
  def display_name
    role_text = case role
    when 'hr' then '人事'
    when 'contract' then '合同'
    when 'boss' then '企业主'
    end
    "#{company.name} · #{role_text}"
  end
  
  private
  
  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
