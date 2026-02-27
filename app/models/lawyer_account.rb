class LawyerAccount < ApplicationRecord
  has_secure_password
  
  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, allow_nil: true
  
  # Normalize email before saving
  before_save :normalize_email
  
  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  
  private
  
  def normalize_email
    self.email = email.downcase.strip if email.present?
  end
end
