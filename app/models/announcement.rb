class Announcement < ApplicationRecord
  # 关联
  belongs_to :company, optional: true  # nil = 全局公告
  belongs_to :created_by, polymorphic: true, optional: true

  # 验证
  validates :title, presence: true
  validates :announcement_type, presence: true, inclusion: {
    in: %w[hearing contract_expiry property_preservation custom]
  }
  validates :priority, presence: true, inclusion: { in: %w[urgent important normal] }

  # Scopes
  scope :published, -> { where('published_at <= ?', Time.current) }
  scope :not_expired, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :active, -> { published.not_expired }
  scope :for_company, ->(company_ids) {
    company_ids = Array(company_ids)
    where('company_id IS NULL OR company_id IN (?)', company_ids)
  }
  scope :ordered, -> { order(priority: :desc, published_at: :desc) }

  # 显示方法
  def type_display
    { 'hearing' => '开庭提醒', 'contract_expiry' => '合同到期',
      'property_preservation' => '保全续封', 'custom' => '通知' }[announcement_type] || '通知'
  end

  def priority_display
    { 'urgent' => '紧急', 'important' => '重要', 'normal' => '提醒' }[priority]
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end
end
