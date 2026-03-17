class MajorIssueFollower < ApplicationRecord
  belongs_to :major_issue, counter_cache: :followers_count
  belongs_to :user, polymorphic: true
  
  validates :user_type, presence: true
  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: [:major_issue_id, :user_type] }
  
  scope :notify_on_comment, -> { where(notify_new_comment: true) }
  scope :notify_on_status, -> { where(notify_status_change: true) }
end
