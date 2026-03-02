class Comment < ApplicationRecord
  # Associations
  belongs_to :commentable, polymorphic: true
  belongs_to :reviewed_by, class_name: 'LawyerAccount', optional: true
  has_many_attached :attachments
  
  # Validations
  validates :author_name, presence: true
  validates :author_role, presence: true
  validates :content, presence: true
  validates :review_status, presence: true, inclusion: { in: %w[pending_review approved rejected] }
  
  # Scopes
  scope :ordered, -> { order(created_at: :asc) }
  scope :approved, -> { where(review_status: 'approved') }
  scope :pending_review, -> { where(review_status: 'pending_review') }
  scope :rejected, -> { where(review_status: 'rejected') }
  
  # Callbacks
  after_create :mark_reviewed_by_lawyer, if: :lawyer_comment?
  before_validation :set_review_status, on: :create
  
  # Maximum file size: 20MB
  MAX_FILE_SIZE = 20.megabytes
  
  # Allowed file types
  ALLOWED_CONTENT_TYPES = %w[
    image/jpeg
    image/png
    image/gif
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
        errors.add(:attachments, "文件 #{attachment.filename} 超过 20MB 限制")
      end
      
      unless ALLOWED_CONTENT_TYPES.include?(attachment.content_type)
        errors.add(:attachments, "文件 #{attachment.filename} 格式不支持")
      end
    end
  end
  
  def lawyer_comment?
    author_role == 'lawyer'
  end
  
  def mark_reviewed_by_lawyer
    return unless commentable.respond_to?(:reviewed_by_lawyer=)
    
    commentable.update_columns(
      reviewed_by_lawyer: true,
      last_lawyer_comment_at: created_at
    )
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
end
