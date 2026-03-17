class CaseNotification < ApplicationRecord
  belongs_to :case
  belongs_to :recipient, polymorphic: true
  
  validates :notification_type, presence: true
  validates :title, presence: true
  
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :ordered, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) if type.present? }
  
  def mark_as_read!
    update(read_at: Time.current) if read_at.nil?
  end
  
  def read?
    read_at.present?
  end
end
