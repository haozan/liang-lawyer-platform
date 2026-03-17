class WorkLog < ApplicationRecord
  include Searchable
  
  # Work log types
  WORK_LOG_TYPES = {
    'communication' => { name: '沟通记录', icon: 'phone', color: 'blue' },
    'investigation' => { name: '调查取证', icon: 'search', color: 'green' },
    'document' => { name: '文书准备', icon: 'file-text', color: 'purple' },
    'trial_prep' => { name: '庭审准备', icon: 'briefcase', color: 'orange' },
    'trial' => { name: '庭审记录', icon: 'scales', color: 'red' },
    'submission' => { name: '材料提交', icon: 'upload', color: 'indigo' },
    'todo' => { name: '待办事项', icon: 'check-square', color: 'yellow' },
    'general' => { name: '其他记录', icon: 'edit', color: 'gray' }
  }.freeze
  
  TODO_STATUSES = %w[pending in_progress completed cancelled].freeze
  
  belongs_to :case
  belongs_to :submitter, polymorphic: true, optional: true
  belongs_to :assigned_to, polymorphic: true, optional: true
  has_many_attached :attachments
  
  # Validations
  validates :date, presence: true
  validates :title, presence: true
  validates :content, presence: true
  validates :log_type, inclusion: { in: WORK_LOG_TYPES.keys }, allow_nil: true
  validates :todo_status, inclusion: { in: TODO_STATUSES }, allow_nil: true
  validate :validate_todo_fields
  
  # Maximum file size per attachment: 40MB
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
  
  # Scopes
  scope :ordered, -> { order(date: :desc, created_at: :desc) }
  scope :by_type, ->(type) { where(log_type: type) if type.present? }
  scope :todos, -> { where(is_todo: true) }
  scope :pending_todos, -> { where(is_todo: true, todo_status: ['pending', 'in_progress']) }
  scope :completed_todos, -> { where(is_todo: true, todo_status: 'completed') }
  scope :overdue_todos, -> { where(is_todo: true, todo_status: ['pending', 'in_progress']).where('due_date < ?', Date.today) }
  scope :upcoming_todos, ->(days = 7) { where(is_todo: true, todo_status: ['pending', 'in_progress']).where('due_date BETWEEN ? AND ?', Date.today, days.days.from_now) }
  
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
  
  def validate_todo_fields
    return unless is_todo
    
    if due_date.blank?
      errors.add(:due_date, '待办事项必须设置截止日期')
    end
    
    if todo_status.blank?
      errors.add(:todo_status, '待办事项必须设置状态')
    end
  end
  
  public
  
  # Type display
  def type_display
    WORK_LOG_TYPES.dig(log_type, :name) || log_type
  end
  
  def type_icon
    WORK_LOG_TYPES.dig(log_type, :icon) || 'edit'
  end
  
  def type_color
    WORK_LOG_TYPES.dig(log_type, :color) || 'gray'
  end
  
  # Todo status display
  def todo_status_display
    case todo_status
    when 'pending' then '待处理'
    when 'in_progress' then '进行中'
    when 'completed' then '已完成'
    when 'cancelled' then '已取消'
    else todo_status
    end
  end
  
  # Todo helpers
  def overdue?
    is_todo && due_date.present? && due_date < Date.today && todo_status.in?(['pending', 'in_progress'])
  end
  
  def complete!
    update(todo_status: 'completed', completed_at: Time.current)
  end
  
  def cancel!
    update(todo_status: 'cancelled')
  end
  
  def reopen!
    update(todo_status: 'pending', completed_at: nil)
  end
  
  # Assigned to display
  def assigned_to_name
    return nil unless assigned_to
    
    case assigned_to
    when LawyerAccount
      assigned_to.name
    when CompanyUser
      assigned_to.name
    else
      '未知'
    end
  end
  
  # 获取提交者名称
  def submitter_name
    return '未知' unless submitter
    
    case submitter
    when LawyerAccount
      role_text = submitter.lawyer? ? '律师' : '律师助理'
      "#{role_text}：#{submitter.name}"
    when CompanyUser
      role_text = submitter.boss? ? '老板' : '员工'
      "企业#{role_text}：#{submitter.name}"
    else
      '未知'
    end
  end
  
  # Searchable implementation
  def search_company_id
    self.case.company_id
  end
  
  def search_title
    "#{self.case.name} - #{title}"
  end
  
  def search_content
    [content, "日期：#{date&.strftime('%Y-%m-%d')}", "提交者：#{submitter_name}"].compact.join(" ")
  end
  
  def search_category
    "工作大事记"
  end
  
  def search_metadata
    {
      date: date,
      case_id: case_id,
      submitter_name: submitter_name
    }
  end
end
