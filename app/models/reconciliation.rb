class Reconciliation < ApplicationRecord
  # Associations
  belongs_to :contract
  has_many_attached :attachments
  
  # Validations
  validates :contract, presence: true
  validates :period, presence: true, format: { with: /\A\d{4}-\d{2}\z/, message: "必须是 YYYY-MM 格式" }
  validates :uploaded_by, presence: true
  validates :uploaded_at, presence: true
  validate :validate_attachments
  
  # Scopes
  scope :ordered, -> { order(period: :desc) }
  
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
  
  private
  
  def validate_attachments
    return unless attachments.attached?
    
    attachments.each do |attachment|
      unless attachment.content_type.in?(%w[image/png image/jpeg image/jpg application/pdf])
        errors.add(:attachments, "只支持 PNG、JPEG、JPG 和 PDF 格式")
      end
      
      if attachment.byte_size > 10.megabytes
        errors.add(:attachments, "单个文件不能超过 10MB")
      end
    end
  end
end
