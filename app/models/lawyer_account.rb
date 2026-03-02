class LawyerAccount < ApplicationRecord
  has_secure_password
  
  # Associations
  has_many :mentioned_issues, class_name: 'MajorIssue', foreign_key: 'mentioned_lawyer_id'
  
  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, allow_nil: true
  validates :role, presence: true, inclusion: { in: %w[assistant lawyer] }
  
  # Normalize email before saving
  before_save :normalize_email
  
  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :lawyers, -> { where(role: 'lawyer') }
  scope :assistants, -> { where(role: 'assistant') }
  
  def lawyer?
    role == 'lawyer'
  end
  
  def assistant?
    role == 'assistant'
  end
  
  # Display name for comments
  def display_name
    role_text = lawyer? ? '律师' : '律师助理'
    "#{name}（#{role_text}）"
  end
  
  private
  
  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
