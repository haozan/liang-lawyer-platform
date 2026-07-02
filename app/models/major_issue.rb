class MajorIssue < ApplicationRecord
  include SoftDeletable
  include DisplayLabels

  # 状态中文映射（用于 status_display）
  STATUS_LABELS = {
    'pending'    => '待讨论',
    'discussing' => '讨论中',
    'resolved'   => '已解决',
    'archived'   => '已归档'
  }.freeze

  # 优先级中文映射（用于 priority_display）
  PRIORITY_LABELS = {
    'low'    => '低',
    'medium' => '中',
    'high'   => '高',
    'urgent' => '紧急'
  }.freeze

  # Serialization
  serialize :team_member_ids, coder: JSON
  
  # Associations
  belongs_to :company
  belongs_to :mentioned_lawyer, class_name: 'LawyerAccount', optional: true
  belongs_to :related_record, polymorphic: true, optional: true
  belongs_to :conclusion_updated_by, polymorphic: true, optional: true
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :followers, class_name: 'MajorIssueFollower', dependent: :destroy
  has_many :read_statuses, class_name: 'MajorIssueReadStatus', dependent: :destroy
  has_many :todo_items, class_name: 'MajorIssueTodoItem', dependent: :destroy
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
  # not_deleted, pending_deletion, deleted scopes 由 SoftDeletable concern 提供
  scope :pending_lawyer_review, -> { where(reviewed_by_lawyer: false) }
  scope :reviewed, -> { where(reviewed_by_lawyer: true) }
  scope :with_unread, ->(user) { 
    joins(:read_statuses)
      .where(major_issue_read_statuses: { user_type: user.class.name, user_id: user.id })
      .where('major_issue_read_statuses.unread_count > 0')
  }
  
  # Status display names（映射由 STATUS_LABELS 常量维护）
  def status_display = display_label(:status, STATUS_LABELS)

  # Priority display names（映射由 PRIORITY_LABELS 常量维护）
  def priority_display = display_label(:priority, PRIORITY_LABELS)
  
  # 软删除方法由 SoftDeletable concern 提供：
  # - request_deletion_by_employee(employee_user)
  # - confirm_deletion_by_boss(boss_user)
  # - delete_by_boss(boss_user)
  # - deleted?
  # - pending_deletion?
  
  # Lawyer review methods
  def needs_lawyer_review?
    !reviewed_by_lawyer
  end
  
  def overdue_for_review?
    return false if reviewed_by_lawyer
    created_at < 3.days.ago
  end
  
  def review_overdue_days
    return 0 if reviewed_by_lawyer || created_at >= 3.days.ago
    ((Time.current - created_at) / 1.day).to_i - 3
  end
  
  def mark_as_reviewed!(lawyer)
    update!(
      reviewed_by_lawyer: true,
      reviewed_at: Time.current,
      reviewed_by_lawyer_id: lawyer.id
    )
  end
  
  # Searchable implementation
  def search_company_id
    company_id
  end
  
  def search_title
    title
  end
  
  def search_content
    [issue_type, description, "状态：#{status_display}", "优先级：#{priority_display}"].compact.join(" ")
  end
  
  def search_category
    "重大法律问题"
  end
  
  def search_metadata
    {
      status: status,
      priority: priority,
      issue_type: issue_type
    }
  end
  
  # 关注功能
  def followed_by?(user)
    followers.exists?(user_type: user.class.name, user_id: user.id)
  end
  
  def follow!(user, notify_comment: true, notify_status: true)
    followers.find_or_create_by!(
      user_type: user.class.name,
      user_id: user.id
    ) do |f|
      f.notify_new_comment = notify_comment
      f.notify_status_change = notify_status
    end
    
    # 创建阅读状态记录
    find_or_create_read_status(user)
  end
  
  def unfollow!(user)
    followers.where(user_type: user.class.name, user_id: user.id).destroy_all
  end
  
  # 阅读状态
  def find_or_create_read_status(user)
    read_statuses.find_or_create_by!(
      user_type: user.class.name,
      user_id: user.id
    )
  end
  
  def mark_as_read_by!(user, comment_id = nil)
    status = find_or_create_read_status(user)
    status.mark_as_read!(comment_id)
  end
  
  def unread_count_for(user)
    read_statuses.find_by(
      user_type: user.class.name,
      user_id: user.id
    )&.unread_count || 0
  end
  
  # 分享链接生成
  def generate_share_token!(expires_in: 7.days)
    self.share_token = SecureRandom.urlsafe_base64(32)
    self.share_expires_at = expires_in.from_now
    save!
    share_token
  end
  
  def share_token_valid?
    share_token.present? && share_expires_at.present? && share_expires_at > Time.current
  end
  
  # 进度追踪
  def update_processing_days!
    return if status == 'resolved' || status == 'archived'
    
    days = ((Time.current - created_at) / 1.day).to_i
    update_column(:processing_days, days)
  end
  
  def overdue?
    processing_days > 7 && status != 'resolved'
  end
  
  # 结论管理
  def update_conclusion!(content, updated_by)
    update!(
      conclusion: content,
      conclusion_updated_at: Time.current,
      conclusion_updated_by: updated_by
    )
  end
  
  def has_conclusion?
    conclusion.present?
  end
  
  # 置顶评论
  def pinned_comments
    comments.where(is_pinned: true).order(pinned_at: :desc)
  end
  
  # 关键意见
  def key_opinion_comments
    comments.where(is_key_opinion: true).order(created_at: :desc)
  end
  
  # 检查所有待办任务是否已完成
  def all_todos_completed?
    return false if todo_items.empty?
    todo_items.where.not(status: 'completed').empty?
  end
  
  # 协作团队成员
  def team_members
    return LawyerAccount.none if team_member_ids.blank?
    LawyerAccount.where(id: team_member_ids)
  end
  
  # 添加协作团队成员
  def add_team_member(lawyer_id)
    self.team_member_ids ||= []
    self.team_member_ids << lawyer_id unless self.team_member_ids.include?(lawyer_id)
    self.team_member_ids.uniq!
  end
  
  # 移除协作团队成员
  def remove_team_member(lawyer_id)
    return if team_member_ids.blank?
    self.team_member_ids.delete(lawyer_id)
  end
  
  # 自动消除相关公告（当所有待办任务完成时）
  def auto_dismiss_announcements_if_todos_completed(user)
    return unless all_todos_completed?
    
    # 消除重大事项相关公告
    begin
      AnnouncementDismissal.dismiss!(
        announcement_type: 'major_issue_review',
        related: self,
        user: user,
        reason: 'all_todos_completed'
      )
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      # 公告已被消除或验证失败，忽略
      Rails.logger.info "公告已被消除或无需消除: #{e.message}"
    rescue => e
      # 其他错误，记录但不阻断执行
      Rails.logger.warn "自动消除公告失败: #{e.message}"
    end
  end
end
