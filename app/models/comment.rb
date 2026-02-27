class Comment < ApplicationRecord
  # Associations
  belongs_to :commentable, polymorphic: true
  has_many_attached :attachments
  
  # Validations
  validates :author_name, presence: true
  validates :author_role, presence: true
  validates :content, presence: true
  
  # Scopes
  scope :ordered, -> { order(created_at: :asc) }
  
  # Callbacks
  after_create :mark_reviewed_by_lawyer, if: :lawyer_comment?
  
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
end
