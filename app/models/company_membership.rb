class CompanyMembership < ApplicationRecord
  belongs_to :company
  belongs_to :company_user

  scope :ordered, -> { order(created_at: :desc) }

  def boss?
    role == 'boss'
  end

  def employee?
    role == 'employee'
  end
end
