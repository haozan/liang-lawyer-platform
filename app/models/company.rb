class Company < ApplicationRecord
  # Associations
  has_many :company_users, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :contracts, dependent: :destroy
  has_many :regulations, dependent: :destroy
  
  # Validations
  validates :name, presence: true, uniqueness: true
  
  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
end
