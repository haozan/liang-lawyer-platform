class MajorIssueReadStatus < ApplicationRecord
  belongs_to :major_issue
  belongs_to :user, polymorphic: true
  
  validates :user_type, presence: true
  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: [:major_issue_id, :user_type] }
  
  scope :with_unread, -> { where('unread_count > 0') }
  
  def mark_as_read!(comment_id = nil)
    update!(
      last_read_at: Time.current,
      last_read_comment_id: comment_id || major_issue.comments.maximum(:id),
      unread_count: 0
    )
  end
  
  def increment_unread!
    increment!(:unread_count)
  end
end
