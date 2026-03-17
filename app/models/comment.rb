class Comment < ApplicationRecord
  # Associations
  belongs_to :commentable, polymorphic: true
  belongs_to :author, polymorphic: true, optional: true
  belongs_to :reviewed_by, class_name: 'LawyerAccount', optional: true
  belongs_to :pinned_by, polymorphic: true, optional: true
  has_many_attached :attachments
  
  # Validations
  validates :author_name, presence: true
  validates :author_role, presence: true
  validates :content, presence: true
  validates :review_status, presence: true, inclusion: { in: %w[pending_review approved rejected] }
  validates :visibility, presence: true, inclusion: { in: %w[public internal] }
  
  # Scopes
  scope :ordered, -> { order(created_at: :asc) }
  scope :approved, -> { where(review_status: 'approved') }
  scope :pending_review, -> { where(review_status: 'pending_review') }
  scope :rejected, -> { where(review_status: 'rejected') }
  scope :public_comments, -> { where(visibility: 'public') }
  scope :internal_comments, -> { where(visibility: 'internal') }
  
  # Callbacks
  after_create :mark_reviewed_by_lawyer, if: :lawyer_comment?
  after_create :auto_dismiss_announcement, if: :lawyer_comment?
  after_create :parse_mentions
  after_create :notify_mentioned_users
  after_create :broadcast_new_comment
  after_create :increment_unread_count
  after_create :trigger_major_issue_status_change
  before_validation :set_review_status, on: :create
  
  # Maximum file size: 40MB
  MAX_FILE_SIZE = 40.megabytes
  
  # Allowed file types
  ALLOWED_CONTENT_TYPES = %w[
    image/jpeg
    image/png
    image/gif
    image/webp
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  ].freeze
  
  # Validate attachment size and content type
  validate :validate_attachments
  
  private
  
  def validate_attachments
    return unless attachments.attached?
    
    attachments.each do |attachment|
      if attachment.byte_size > MAX_FILE_SIZE
        errors.add(:attachments, "文件 #{attachment.filename} 不得大于 40MB")
      end
      
      unless ALLOWED_CONTENT_TYPES.include?(attachment.content_type)
        errors.add(:attachments, "文件 #{attachment.filename} 格式不支持，仅支持图片、PDF、Word、Excel文件")
      end
    end
  end
  
  def lawyer_comment?
    author_role.in?(['lawyer', 'senior_lawyer', 'team_leader', 'super_admin'])
  end
  
  def mark_reviewed_by_lawyer
    return unless commentable.respond_to?(:reviewed_by_lawyer=)
    
    # 只更新存在的字段
    update_hash = { reviewed_by_lawyer: true }
    update_hash[:last_lawyer_comment_at] = created_at if commentable.respond_to?(:last_lawyer_comment_at=)
    
    commentable.update_columns(update_hash)
  end
  
  def auto_dismiss_announcement
    return unless commentable
    return unless author_role.present?
    
    # 检查是否为律师角色（包括 lawyer, senior_lawyer, team_leader, super_admin）
    is_lawyer_role = author_role.in?(['lawyer', 'senior_lawyer', 'team_leader', 'super_admin'])
    return unless is_lawyer_role
    
    # 确定公告类型
    announcement_type = case commentable.class.name
    when 'Contract'
      'contract_review'
    when 'MajorIssue'
      'major_issue_review'
    when 'Reconciliation'
      'reconciliation_review'
    else
      return
    end
    
    # 尝试获取律师账户
    begin
      # 优先使用 author 关联（author_id + author_type）
      lawyer = if author && author.is_a?(LawyerAccount)
                 author
               elsif author_id.present? && author_type == 'LawyerAccount'
                 LawyerAccount.find_by(id: author_id)
               elsif author_name.present?
                 # 从 author_name 推断（去除"（律师）"等后缀）
                 clean_name = author_name.gsub(/[（(].*?[）)]/, '').strip
                 LawyerAccount.find_by('name LIKE ?', "%#{clean_name}%")
               end
      
      return unless lawyer
      
      AnnouncementDismissal.dismiss!(
        announcement_type: announcement_type,
        related: commentable,
        user: lawyer,
        reason: 'reviewed'
      )
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      # 公告已被消除，忽略
      Rails.logger.info "公告已被消除或无需消除: #{e.message}"
    rescue => e
      # 其他错误，记录但不阻断
      Rails.logger.warn "自动消除公告失败: #{e.message}"
    end
  end
  
  def set_review_status
    # 律师的评论自动审核通过，助理的评论需要审核
    self.review_status ||= if author_role == 'lawyer'
                             'approved'
                           elsif author_role == 'assistant'
                             'pending_review'
                           else
                             'approved'
                           end
  end
  
  public
  
  def needs_review?
    review_status == 'pending_review'
  end
  
  def approved?
    review_status == 'approved'
  end
  
  def rejected?
    review_status == 'rejected'
  end
  
  def approve_by(lawyer)
    update(
      review_status: 'approved',
      reviewed_by: lawyer,
      reviewed_at: Time.current
    )
  end
  
  def reject_by(lawyer)
    update(
      review_status: 'rejected',
      reviewed_by: lawyer,
      reviewed_at: Time.current
    )
  end
  
  # 检查评论是否可以删除（30分钟内）
  def can_be_deleted?
    created_at >= 30.minutes.ago
  end
  
  # 可见性检查
  def public?
    visibility == 'public'
  end
  
  def internal?
    visibility == 'internal'
  end
  
  # 检查用户是否可以查看此评论
  def visible_to?(user)
    return true if public?
    return false unless internal?
    
    # 内部评论仅律师团队可见
    return false unless user.is_a?(LawyerAccount)
    
    # 检查是否是主责律师或协作团队成员
    if commentable.is_a?(Contract)
      return true if commentable.assigned_lawyer_id == user.id
      return true if commentable.assistant_lawyer_ids&.include?(user.id)
    elsif commentable.is_a?(Reconciliation)
      contract = commentable.contract
      return true if contract.assigned_lawyer_id == user.id
      return true if contract.assistant_lawyer_ids&.include?(user.id)
    elsif commentable.is_a?(MajorIssue)
      return true if commentable.mentioned_lawyer_id == user.id
      return true if commentable.team_member_ids&.include?(user.id)
    end
    
    # 超级管理员和团队负责人可见所有内部评论
    user.super_admin? || user.role == 'team_leader'
  end
  
  # 检查当前用户是否可以删除此评论
  def deletable_by?(user)
    return false unless can_be_deleted?
    return false unless user
    
    # 直接使用author关联进行比较
    author == user
  end
  
  # 置顶功能
  def pin!(user)
    update!(
      is_pinned: true,
      pinned_at: Time.current,
      pinned_by: user
    )
  end
  
  def unpin!
    update!(
      is_pinned: false,
      pinned_at: nil,
      pinned_by: nil
    )
  end
  
  # 标记为关键意见
  def mark_as_key_opinion!
    update!(is_key_opinion: true)
  end
  
  def unmark_as_key_opinion!
    update!(is_key_opinion: false)
  end
  
  # 解析@提醒
  def parse_mentions
    return unless content.present?
    
    mentioned_ids = []
    
    # 匹配 @律师名字 或 @公司用户名
    content.scan(/@([\w\u4e00-\u9fa5]+)/) do |match|
      username = match[0]
      
      # 查找律师账户（按姓名或手机号）
      lawyer = LawyerAccount.find_by("name LIKE ? OR phone LIKE ?", "%#{username}%", "%#{username}%")
      if lawyer
        mentioned_ids << { type: 'LawyerAccount', id: lawyer.id }
        next
      end
      
      # 查找公司用户（按姓名或手机号）
      if commentable.respond_to?(:company)
        company_user = commentable.company.company_users.find_by("name LIKE ? OR phone LIKE ?", "%#{username}%", "%#{username}%")
        if company_user
          mentioned_ids << { type: 'CompanyUser', id: company_user.id }
        end
      end
    end
    
    self.mentioned_user_ids = mentioned_ids if mentioned_ids.any?
  end
  
  # 通知被@的用户
  def notify_mentioned_users
    return if mentioned_user_ids.blank?
    
    mentioned_user_ids.each do |user_info|
      user_class = user_info['type'].constantize
      user = user_class.find_by(id: user_info['id'])
      next unless user
      
      # TODO: 发送通知（邮件/站内消息）
      # MentionNotificationJob.perform_later(comment: self, user: user)
    end
  end
  
  # 广播新评论（ActionCable）
  def broadcast_new_comment
    return unless commentable.is_a?(MajorIssue)
    
    ActionCable.server.broadcast(
      "major_issue_#{commentable.id}",
      {
        type: 'new_comment',
        comment_id: id,
        author_name: author_name,
        author_role: author_role,
        content: content,
        created_at: created_at.iso8601
      }
    )
  end
  
  # 增加未读计数
  def increment_unread_count
    return unless commentable.is_a?(MajorIssue)
    
    # 为所有关注者增加未读计数（除了评论作者）
    commentable.read_statuses.where.not(
      user_type: author_type,
      user_id: author_id
    ).find_each(&:increment_unread!)
  end
  
  # 触发重大事项状态变更
  def trigger_major_issue_status_change
    return unless commentable.is_a?(MajorIssue)
    return unless commentable.may_start_discussing?
    
    # 如果是第一条评论，自动从pending变为discussing
    commentable.start_discussing!
  end
end
