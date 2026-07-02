class MajorIssue < ApplicationRecord
  # === 关联 ===
  belongs_to :company
  has_many :comments, as: :commentable, dependent: :destroy
  has_many_attached :attachments

  # === 验证 ===
  validates :title, presence: true
  validates :description, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending resolved] }

  # === Scopes ===
  scope :ordered, -> { order(created_at: :desc) }
  scope :pending, -> { where(status: 'pending') }
  scope :resolved, -> { where(status: 'resolved') }

  # === 显示方法 ===
  def status_display
    status == 'pending' ? '待处理' : '已解决'
  end

  def status_badge_color
    status == 'pending' ? 'warning' : 'success'
  end

  # === 操作 ===
  def resolve!
    update!(status: 'resolved', resolved_at: Time.current)
  end
end
