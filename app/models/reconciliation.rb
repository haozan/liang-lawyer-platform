class Reconciliation < ApplicationRecord
  # === 关联 ===
  belongs_to :contract
  has_many :comments, as: :commentable, dependent: :destroy
  has_many_attached :attachments

  # === 验证 ===
  validates :contract, presence: true
  validates :period, presence: true, format: { with: /\A\d{4}-\d{2}\z/, message: "必须是 YYYY-MM 格式" }
  validates :uploaded_by, presence: true
  validates :uploaded_at, presence: true
  validates :receivable_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :received_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :validate_attachments, if: -> { attachments.attached? }

  # === Scopes ===
  scope :ordered, -> { order(period: :desc) }
  scope :pending_review, -> { where(reviewed_by_lawyer: false) }
  scope :reviewed, -> { where(reviewed_by_lawyer: true) }

  # === 显示方法 ===
  def period_display
    return '' unless period
    year, month = period.split('-')
    "#{year}年#{month}月"
  end

  # === 应收/实收差额 ===
  def difference_amount
    return nil unless receivable_amount.present? && received_amount.present?
    receivable_amount - received_amount
  end

  def has_gap?
    diff = difference_amount
    diff.present? && diff > 0
  end

  # === 律师审查 ===
  def mark_as_reviewed!(lawyer)
    update!(
      reviewed_by_lawyer: true,
      reviewed_at: Time.current,
      reviewed_by_lawyer_id: lawyer.id
    )
  end

  private

  def validate_attachments
    attachments.each do |attachment|
      unless attachment.content_type.in?(%w[image/png image/jpeg image/jpg application/pdf])
        errors.add(:attachments, "只支持 PNG、JPEG、JPG 和 PDF 格式")
      end
      if attachment.byte_size > 40.megabytes
        errors.add(:attachments, "单个文件不得大于 40MB")
      end
    end
  end
end
