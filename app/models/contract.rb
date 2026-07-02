class Contract < ApplicationRecord
  include DisplayLabels

  # 状态中文映射（用于 status_display）
  STATUS_LABELS = {
    'active'     => '执行中',
    'completed'  => '已完成',
    'breach'     => '已违约',
    'litigation' => '诉讼中'
  }.freeze

  # Associations
  belongs_to :company
  belongs_to :related_case, class_name: 'Case', optional: true
  belongs_to :assigned_lawyer, class_name: 'LawyerAccount', optional: true
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :reconciliations, dependent: :destroy
  has_many :contract_taggings, dependent: :destroy
  has_many :tags, through: :contract_taggings, source: :tag, class_name: 'ContractTag'
  
  # 律师助理关联（通过 assistant_lawyer_ids 数组）
  def assistant_lawyers
    return LawyerAccount.none if assistant_lawyer_ids.blank?
    LawyerAccount.where(id: assistant_lawyer_ids)
  end
  has_one_attached :file
  has_many_attached :supplement_files
  has_many_attached :annex_files
  has_many_attached :delivery_proofs
  has_many_attached :payment_proofs
  has_many_attached :correspondence_files
  has_many_attached :other_evidence_files
  
  # Validations
  validates :name, presence: true
  validates :signed_at, presence: true
  validates :end_at, presence: true
  validates :status, presence: true, inclusion: { in: %w[active completed breach litigation] }
  validates :file, presence: true
  
  # 新增字段验证
  validates :counterparty_name, presence: true
  validates :counterparty_role, presence: true
  validates :our_party_role, presence: true
  validates :contract_type, presence: true
  validates :contract_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :liquidated_damages, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :litigation_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :performance_progress, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :renewal_notice_period, numericality: { greater_than: 0 }, allow_nil: true
  
  # 枚举值验证
  validates :contract_type, inclusion: { 
    in: %w[买卖合同 服务合同 租赁合同 借款合同 建设工程合同 技术合同 承揽合同 运输合同 保管合同 委托合同 其他], 
    allow_blank: true 
  }
  validates :counterparty_type, inclusion: { in: %w[企业 个人 政府机关 其他], allow_blank: true }
  validates :legal_risk_level, inclusion: { in: %w[低 中 高 极高], allow_blank: true }
  validates :legal_review_status, inclusion: { in: %w[待审查 已审查 有风险 高风险], allow_blank: true }
  validates :performance_status, inclusion: { 
    in: %w[未开始履行 正常履行中 部分履行 履行完毕 对方违约 我方违约 协商变更中 已解除 已终止], 
    allow_blank: true 
  }
  validates :dispute_status, inclusion: { in: %w[无争议 协商中 调解中 仲裁中 诉讼中 已结案], allow_blank: true }
  validates :dispute_resolution, inclusion: { in: %w[协商 调解 仲裁 诉讼], allow_blank: true }
  validates :renewal_intention, inclusion: { in: %w[续约 不续约 待定], allow_blank: true }
  
  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :active, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
  scope :breach, -> { where(status: 'breach') }
  scope :litigation, -> { where(status: 'litigation') }
  scope :expiring_soon, -> { where(status: 'active').where('end_at <= ?', 30.days.from_now).where('end_at >= ?', Date.today) }
  scope :pending_lawyer_review, -> { where(reviewed_by_lawyer: false) }
  scope :new_files, -> { where('created_at >= ?', 3.days.ago) }
  scope :tagged_with, ->(tag_ids) { joins(:contract_taggings).where(contract_taggings: { tag_id: tag_ids }).distinct }
  
  # Status display names（映射由 STATUS_LABELS 常量维护）
  def status_display = display_label(:status, STATUS_LABELS)
  
  # 新增字段辅助方法
  def has_high_risk?
    legal_risk_level.in?(['高', '极高'])
  end
  
  def in_dispute?
    dispute_status.present? && dispute_status != '无争议'
  end
  
  def needs_renewal_notice?
    return false unless auto_renewal && renewal_notice_period && end_at
    end_at <= renewal_notice_period.days.from_now.to_date && end_at > Date.today
  end
  
  def performance_on_track?
    performance_status.in?(['未开始履行', '正常履行中', '履行完毕'])
  end
  
  def has_case?
    related_case_id.present?
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
  
  # Searchable implementation
  def search_company_id
    company_id
  end
  
  def search_title
    name
  end
  
  def search_content
    ["签订日期：#{signed_at&.strftime('%Y-%m-%d')}", "到期日期：#{end_at&.strftime('%Y-%m-%d')}", "状态：#{status_display}"].compact.join(" ")
  end
  
  def search_category
    "合同档案"
  end
  
  def search_metadata
    {
      status: status,
      signed_at: signed_at,
      end_at: end_at,
      expiring_soon: expiring_soon?,
      expired: expired?
    }
  end
end
