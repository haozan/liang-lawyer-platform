class Announcement < ApplicationRecord
  # Associations
  belongs_to :company, optional: true # nil = 全局公告
  belongs_to :related, polymorphic: true, optional: true # 关联的业务对象
  belongs_to :created_by, polymorphic: true, optional: true # System 或 LawyerAccount
  has_many :read_statuses, class_name: 'AnnouncementReadStatus', dependent: :destroy
  
  # Validations
  validates :title, presence: true
  validates :announcement_type, presence: true, inclusion: { 
    in: %w[hearing contract_expiry contract_review reconciliation_overdue judgement_collection property_preservation custom] 
  }
  validates :priority, presence: true, inclusion: { in: %w[urgent important normal] }
  
  # Scopes
  scope :published, -> { where('published_at <= ?', Time.current) }
  scope :not_expired, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :active, -> { published.not_expired }
  scope :urgent, -> { where(priority: 'urgent') }
  scope :important, -> { where(priority: 'important') }
  scope :for_company, ->(company_ids) { 
    company_ids = Array(company_ids)
    where('company_id IS NULL OR company_id IN (?)', company_ids) 
  }
  scope :ordered, -> { order(priority: :desc, published_at: :desc) }
  
  # 公告类型显示名称
  def type_display
    case announcement_type
    when 'hearing' then '开庭提醒'
    when 'contract_expiry' then '合同到期'
    when 'contract_review' then '待审查合同'
    when 'reconciliation_overdue' then '待上传对账单'
    when 'judgement_collection' then '待领取判决书'
    when 'property_preservation' then '财产保全到期'
    when 'custom' then '通知'
    end
  end
  
  # 优先级显示名称
  def priority_display
    case priority
    when 'urgent' then '紧急'
    when 'important' then '重要'
    when 'normal' then '提醒'
    end
  end
  
  # 优先级对应的颜色类
  def priority_color_class
    case priority
    when 'urgent' then 'red'
    when 'important' then 'orange'
    when 'normal' then 'blue'
    end
  end
  
  # 检查是否已过期
  def expired?
    expires_at.present? && expires_at < Time.current
  end
  
  # 检查用户是否已读（仅手动公告）
  def read_by?(user)
    return false unless user
    read_statuses.exists?(user_type: user.class.name, user_id: user.id)
  end
  
  # 标记为已读
  def mark_as_read_by(user)
    return false unless user
    read_statuses.find_or_create_by(
      user_type: user.class.name,
      user_id: user.id
    ) do |status|
      status.read_at = Time.current
    end
  end
end
