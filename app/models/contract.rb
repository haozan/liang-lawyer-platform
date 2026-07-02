class Contract < ApplicationRecord
  include DisplayLabels

  # === 常量 ===
  STATUS_LABELS = {
    'active'     => '执行中',
    'completed'  => '已完成',
    'breach'     => '已违约',
    'litigation' => '诉讼中'
  }.freeze

  CONTRACT_TYPES = %w[买卖合同 服务合同 租赁合同 借款合同 建设工程合同 技术合同 承揽合同 运输合同 保管合同 委托合同 其他].freeze

  # === 关联 ===
  belongs_to :company
  belongs_to :assigned_lawyer, class_name: 'LawyerAccount', optional: true
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :reconciliations, dependent: :destroy
  has_one_attached :file                    # 合同文件
  has_many_attached :supplement_files       # 补充材料（统一附件）

  # === 验证 ===
  validates :name, presence: true
  validates :signed_at, presence: true
  validates :end_at, presence: true
  validates :status, presence: true, inclusion: { in: %w[active completed breach litigation] }
  validates :file, presence: true
  validates :counterparty_name, presence: true
  validates :contract_type, inclusion: { in: CONTRACT_TYPES, allow_blank: true }
  validates :contract_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # === Scopes ===
  scope :ordered, -> { order(created_at: :desc) }
  scope :active, -> { where(status: 'active') }
  scope :expiring_soon, -> { where(status: 'active').where('end_at <= ?', 30.days.from_now).where('end_at >= ?', Date.today) }
  scope :pending_review, -> { where(reviewed_by_lawyer: false) }

  # === 显示方法 ===
  def status_display = display_label(:status, STATUS_LABELS)

  # === 到期提醒 ===
  def expiring_soon?
    status == 'active' && end_at.present? && end_at <= 30.days.from_now.to_date && end_at >= Date.today
  end

  def expired?
    end_at.present? && end_at < Date.today
  end

  # === 律师审查 ===
  def needs_lawyer_review?
    !reviewed_by_lawyer
  end

  # === 对账 ===
  def reconciliation_uploaded_this_month?
    reconciliations.where(period: Date.today.strftime('%Y-%m')).exists?
  end

  def reconciliation_overdue?
    status == 'active' && end_at.present? && end_at > Date.today && !reconciliation_uploaded_this_month?
  end

  # === 访问控制 ===
  def self.accessible_by(lawyer_account)
    all
  end
end
