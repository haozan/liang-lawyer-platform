class Case < ApplicationRecord
  # Associations
  belongs_to :company
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :work_logs, dependent: :destroy
  
  # Active Storage attachments
  has_many_attached :attachments # 案件通用附件
  has_many_attached :filing_attachments # 立案日期附件(受理通知书)
  has_many_attached :hearing_attachments # 开庭时间附件(传票)
  has_many_attached :judgement_attachments # 领取判决书附件(判决书扫描件)
  has_many_attached :archived_attachments # 归档日期附件
  
  # Validations
  validates :name, presence: true
  validates :case_number, presence: true, uniqueness: { scope: :company_id }, unless: -> { status == 'pending' }
  validates :case_type, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending investigating in_court judgement closed] }
  validates :stage, inclusion: { in: %w[arbitration first_trial second_trial execution retrial resume_execution], allow_nil: true }
  validates :filing_at, presence: true, unless: -> { status == 'pending' }
  
  # Scopes
  scope :ordered, -> { order(filing_at: :desc) }
  scope :pending, -> { where(status: 'pending') }
  scope :active, -> { where(status: ['investigating', 'in_court']) }
  scope :closed, -> { where(status: 'closed') }
  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :pending_deletion, -> { where.not(deleted_by_employee_id: nil).where(deleted_at: nil) }
  
  # Status display names
  def status_display
    case status
    when 'pending' then '待立案'
    when 'investigating' then '调查取证'
    when 'in_court' then '庭审中'
    when 'judgement' then '已判决'
    when 'closed' then '已结案'
    end
  end
  
  # Stage display names
  def stage_display
    return nil if stage.blank?
    case stage
    when 'arbitration' then '仲裁'
    when 'first_trial' then '一审'
    when 'second_trial' then '二审'
    when 'execution' then '执行'
    when 'retrial' then '再审'
    when 'resume_execution' then '恢复执行'
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
  
  # 权限判断方法
  
  # 是否已归档
  def archived?
    archived_at.present?
  end
  
  # 企业用户是否可以编辑工作大事记
  def can_company_user_edit_work_logs?(user)
    return false unless user.is_a?(CompanyUser)
    return false unless user.company_id == company_id
    # 普通员工和老板都可以编辑工作大事记
    user.employee? || user.boss?
  end
  
  # 企业用户是否可以编辑案件基本信息
  def can_company_user_edit_case_info?(user)
    # 企业用户不能编辑案件基本信息，只有律师可以
    false
  end
  
  # 企业用户是否可以查阅案件
  def can_company_user_view?(user)
    return false unless user.is_a?(CompanyUser)
    user.company_id == company_id
  end
  
  # 企业用户是否可以下载案件附件
  def can_company_user_download_attachments?(user)
    return false unless user.is_a?(CompanyUser)
    user.company_id == company_id
  end
  
  # 老板是否可以下载归档档案
  def can_boss_download_archive?(user)
    return false unless user.is_a?(CompanyUser)
    return false unless user.company_id == company_id
    return false unless archived? # 必须已归档
    user.boss? # 必须是老板
  end
end
