class MajorIssueTodoItem < ApplicationRecord
  belongs_to :major_issue
  belongs_to :assignee, polymorphic: true, optional: true
  belongs_to :creator, polymorphic: true
  belongs_to :completed_by, polymorphic: true, optional: true
  
  validates :title, presence: true
  validates :status, inclusion: { in: %w[pending in_progress completed cancelled] }
  
  scope :pending, -> { where(status: 'pending') }
  scope :in_progress, -> { where(status: 'in_progress') }
  scope :completed, -> { where(status: 'completed') }
  scope :overdue, -> { where('due_date < ? AND status != ?', Date.current, 'completed') }
  
  def complete!(user)
    transaction do
      update!(
        status: 'completed',
        completed_at: Time.current,
        completed_by: user
      )
      
      # 检查是否所有待办都已完成，如果是则自动消除相关公告
      major_issue.auto_dismiss_announcements_if_todos_completed(user)
    end
  end
  
  def overdue?
    due_date.present? && due_date < Date.current && status != 'completed'
  end
end
