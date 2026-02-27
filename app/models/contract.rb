class Contract < ApplicationRecord
  # Associations
  belongs_to :company
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :reconciliations, dependent: :destroy
  has_one_attached :file
  
  # Validations
  validates :name, presence: true
  validates :signed_at, presence: true
  validates :end_at, presence: true
  validates :status, presence: true, inclusion: { in: %w[active completed breach litigation] }
  validates :file, presence: true
  
  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :active, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
  scope :breach, -> { where(status: 'breach') }
  scope :litigation, -> { where(status: 'litigation') }
  scope :expiring_soon, -> { where(status: 'active').where('end_at <= ?', 30.days.from_now).where('end_at >= ?', Date.today) }
  scope :pending_lawyer_review, -> { where(reviewed_by_lawyer: false) }
  scope :new_files, -> { where('created_at >= ?', 3.days.ago) }
  
  # Status display names
  def status_display
    case status
    when 'active' then '执行中'
    when 'completed' then '已完成'
    when 'breach' then '已违约'
    when 'litigation' then '诉讼中'
    end
  end
  
  # Check if contract is expiring soon (within 30 days)
  def expiring_soon?
    return false unless end_at
    status == 'active' && end_at <= 30.days.from_now.to_date && end_at >= Date.today
  end
  
  # Check if contract has expired
  def expired?
    return false unless end_at
    end_at < Date.today
  end
  
  # Check if contract is cross-month (signed and end dates are in different months)
  def cross_month?
    return false unless signed_at && end_at
    signed_at.beginning_of_month != end_at.beginning_of_month
  end
  
  # Check if reconciliation has been uploaded for current month
  def reconciliation_uploaded_this_month?
    reconciliations.where(period: Date.today.strftime('%Y-%m')).exists?
  end
  
  # Check if reconciliation is overdue (cross-month contract without this month's reconciliation)
  def reconciliation_overdue?
    cross_month? && status == 'active' && !reconciliation_uploaded_this_month?
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
    if (expiring_soon? || reconciliation_overdue?) && !reviewed_by_lawyer
      0 # 高优先级：合同即将到期或对账单逾期
    elsif created_at >= 3.days.ago && !reviewed_by_lawyer
      1 # 中优先级：新上传的合同
    else
      1
    end
  end
end
