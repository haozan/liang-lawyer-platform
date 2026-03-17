class AnnouncementDismissal < ApplicationRecord
  # Associations
  belongs_to :related, polymorphic: true
  belongs_to :user, polymorphic: true
  
  # Validations
  validates :announcement_type, presence: true
  validates :dismissal_reason, presence: true
  validates :dismissed_at, presence: true
  validates :announcement_type, uniqueness: { 
    scope: [:related_type, :related_id, :user_type, :user_id],
    message: "该公告已被此用户消除"
  }
  
  # Scopes
  scope :for_user, ->(user) { where(user_type: user.class.name, user_id: user.id) }
  scope :for_type, ->(type) { where(announcement_type: type) }
  scope :for_related, ->(related) { where(related_type: related.class.name, related_id: related.id) }
  scope :ordered, -> { order(dismissed_at: :desc) }
  
  # 检查某个公告是否已被消除（针对特定用户）
  def self.dismissed_by_user?(announcement_type, related_object, user)
    exists?(
      announcement_type: announcement_type,
      related_type: related_object.class.name,
      related_id: related_object.id,
      user_type: user.class.name,
      user_id: user.id
    )
  end
  
  # 检查某个公告是否已被任何人消除（系统级消除）
  def self.dismissed?(announcement_type, related_object)
    exists?(
      announcement_type: announcement_type,
      related_type: related_object.class.name,
      related_id: related_object.id
    )
  end
  
  # 消除公告（创建消除记录）
  def self.dismiss!(announcement_type:, related:, user:, reason: 'manual')
    create!(
      announcement_type: announcement_type,
      related: related,
      user: user,
      dismissal_reason: reason,
      dismissed_at: Time.current
    )
  end
  
  # 恢复公告（删除消除记录）
  def self.restore!(announcement_type:, related:, user:)
    where(
      announcement_type: announcement_type,
      related_type: related.class.name,
      related_id: related.id,
      user_type: user.class.name,
      user_id: user.id
    ).destroy_all
  end
end
