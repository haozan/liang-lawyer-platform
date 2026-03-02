class MajorIssue < ApplicationRecord
  # Associations
  belongs_to :company
  belongs_to :mentioned_lawyer, class_name: 'LawyerAccount', optional: true
  has_many :comments, as: :commentable, dependent: :destroy
  has_many_attached :attachments
  
  # Validations
  validates :title, presence: true
  validates :issue_type, presence: true
  validates :priority, presence: true, inclusion: { in: %w[low medium high urgent] }
  validates :status, presence: true, inclusion: { in: %w[pending discussing resolved archived] }
  validates :description, presence: true
  
  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :pending, -> { where(status: 'pending') }
  scope :discussing, -> { where(status: 'discussing') }
  scope :resolved, -> { where(status: 'resolved') }
  scope :high_priority, -> { where(priority: ['high', 'urgent']) }
  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :pending_deletion, -> { where.not(deleted_by_employee_id: nil).where(deleted_at: nil) }
  
  # Status display names
  def status_display
    case status
    when 'pending' then '待讨论'
    when 'discussing' then '讨论中'
    when 'resolved' then '已解决'
    when 'archived' then '已归档'
    end
  end
  
  # Priority display names
  def priority_display
    case priority
    when 'low' then '低'
    when 'medium' then '中'
    when 'high' then '高'
    when 'urgent' then '紧急'
    end
  end
  
  # Soft delete by employee (requires boss confirmation)
  def request_deletion_by_employee(employee_user)
    update(deleted_by_employee_id: employee_user.id, deletion_requested_at: Time.current)
  end
  
  # Boss confirms deletion
  def confirm_deletion_by_boss(boss_user)
    update(confirmed_by_boss_id: boss_user.id, deleted_at: Time.current)
  end
  
  # Boss can delete directly
  def delete_by_boss(boss_user)
    update(deleted_by_employee_id: boss_user.id, confirmed_by_boss_id: boss_user.id, deleted_at: Time.current)
  end
  
  def deleted?
    deleted_at.present?
  end
  
  def pending_deletion?
    deleted_by_employee_id.present? && deleted_at.nil?
  end
end
