class Reconciliation < ApplicationRecord
  
  # Associations
  belongs_to :contract
  has_many :comments, as: :commentable, dependent: :destroy
  has_many_attached :attachments
  
  # Validations
  validates :contract, presence: true
  validates :period, presence: true, format: { with: /\A\d{4}-\d{2}\z/, message: "必须是 YYYY-MM 格式" }
  validates :uploaded_by, presence: true
  validates :uploaded_at, presence: true
  validate :validate_attachments, if: -> { attachments.attached? }
  
  # mentioned_users structure: [{"type": "LawyerAccount", "id": 1, "name": "张律师"}, ...]
  # Store as JSON array
  
  # Scopes
  scope :ordered, -> { order(period: :desc) }
  scope :pending_lawyer_review, -> { where(reviewed_by_lawyer: false) }
  scope :reviewed, -> { where(reviewed_by_lawyer: true) }
  scope :for_contract, ->(contract_id) { where(contract_id: contract_id) }
  
  # Period display name
  def period_display
    return '' unless period
    year, month = period.split('-')
    "#{year}年#{month}月"
  end
  
  # Check if this month's reconciliation is uploaded
  def self.current_month_uploaded?(contract)
    current_period = Time.current.strftime('%Y-%m')
    contract.reconciliations.exists?(period: current_period)
  end
  
  # Lawyer review methods
  def needs_lawyer_review?
    !reviewed_by_lawyer
  end
  
  def overdue_for_review?
    return false if reviewed_by_lawyer
    uploaded_at < 3.days.ago
  end
  
  def review_overdue_days
    return 0 if reviewed_by_lawyer || uploaded_at >= 3.days.ago
    ((Time.current - uploaded_at) / 1.day).to_i - 3
  end
  
  def mark_as_reviewed!(lawyer)
    update!(
      reviewed_by_lawyer: true,
      reviewed_at: Time.current,
      reviewed_by_lawyer_id: lawyer.id
    )
  end
  
  private
  
  def validate_attachments
    return unless attachments.attached?
    
    attachments.each do |attachment|
      unless attachment.content_type.in?(%w[image/png image/jpeg image/jpg application/pdf])
        errors.add(:attachments, "只支持 PNG、JPEG、JPG 和 PDF 格式")
      end
      
      if attachment.byte_size > 40.megabytes
        errors.add(:attachments, "单个文件不得大于 40MB")
      end
    end
  end
  
  # Searchable implementation
  def search_company_id
    contract.company_id
  end
  
  def search_title
    "#{contract.name} - #{period_display}对账单"
  end
  
  def search_content
    [notes, "上传者：#{uploaded_by}", "上传时间：#{uploaded_at&.strftime('%Y-%m-%d')}"].compact.join(" ")
  end
  
  def search_category
    "对账单"
  end
  
  def search_metadata
    {
      period: period,
      uploaded_by: uploaded_by,
      uploaded_at: uploaded_at,
      contract_id: contract_id
    }
  end
end
