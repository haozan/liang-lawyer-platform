class Employee < ApplicationRecord
  # Associations
  belongs_to :company
  has_many :comments, as: :commentable, dependent: :destroy
  
  # Validations
  validates :name, presence: true
  validates :id_number, presence: true
  validates :position, presence: true
  validates :hired_at, presence: true
  validates :contract_signed_at, presence: true
  validates :contract_end_at, presence: true
  validates :gender, inclusion: { in: %w[男 女], allow_blank: true }
  
  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :expiring_soon, -> { where('contract_end_at <= ?', 30.days.from_now).where('contract_end_at >= ?', Date.today) }
  scope :pending_lawyer_review, -> { where(reviewed_by_lawyer: false) }
  scope :new_files, -> { where('created_at >= ?', 3.days.ago) }
  
  # Check if contract is expiring soon (within 30 days)
  def contract_expiring_soon?
    return false unless contract_end_at
    contract_end_at <= 30.days.from_now.to_date && contract_end_at >= Date.today
  end
  
  # Check if contract has expired
  def contract_expired?
    return false unless contract_end_at
    contract_end_at < Date.today
  end
  
  # Lawyer review methods
  def needs_lawyer_review?
    !reviewed_by_lawyer
  end
  
  def overdue_for_review?
    return false if reviewed_by_lawyer
    created_at < 3.days.ago
  end
  
  def overdue_days
    return 0 if reviewed_by_lawyer || created_at >= 3.days.ago
    ((Time.current - created_at) / 1.day).to_i - 3
  end
  
  # Priority: 0=高优先级, 1=中优先级, 2=低优先级
  def lawyer_review_priority
    if contract_expiring_soon? && !reviewed_by_lawyer
      0 # 高优先级：合同即将到期
    elsif created_at >= 3.days.ago && !reviewed_by_lawyer
      2 # 低优先级：新上传的员工档案
    else
      2
    end
  end
end
