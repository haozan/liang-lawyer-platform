class AnnouncementReadStatus < ApplicationRecord
  # Associations
  belongs_to :announcement
  belongs_to :user, polymorphic: true
  
  # Validations
  validates :announcement_id, presence: true
  validates :user_type, presence: true
  validates :user_id, presence: true
  validates :read_at, presence: true
  validates :announcement_id, uniqueness: { scope: [:user_type, :user_id] }
end
