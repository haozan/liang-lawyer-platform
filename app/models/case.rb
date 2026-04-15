class Case < ApplicationRecord
  include Searchable
  include CaseFilterable
  include TeamAccessible
  include SoftDeletable
  include DisplayLabels

  # 状态中文映射（用于 status_display）
  STATUS_LABELS = {
    'preparing'  => '准备立案',
    'filed'      => '已立案待审',
    'trial'      => '审理中',
    'judged'     => '已判决',
    'execution'  => '执行中',
    'settled'    => '调解结案',
    'closed'     => '已归档'
  }.freeze

  # Priority levels
  PRIORITIES = {
    'urgent' => '紧急',
    'high' => '高',
    'normal' => '普通',
    'low' => '低'
  }.freeze
  
  # Party roles (诉讼地位)
  PARTY_ROLES = {
    # 一审/仲裁阶段
    '原告' => '原告/申请人',
    '被告' => '被告/被申请人',
    # 二审阶段
    '上诉人' => '上诉人',
    '被上诉人' => '被上诉人',
    # 再审阶段
    '再审申请人' => '再审申请人',
    '再审被申请人' => '再审被申请人',
    # 执行阶段
    '申请执行人' => '申请执行人',
    '被执行人' => '被执行人'
  }.freeze
  
  # Available party roles by stage
  PARTY_ROLES_BY_STAGE = {
    'arbitration' => ['原告', '被告'],
    'first_trial' => ['原告', '被告'],
    'second_trial' => ['上诉人', '被上诉人'],
    'execution' => ['申请执行人', '被执行人'],
    'retrial' => ['再审申请人', '再审被申请人'],
    'resume_execution' => ['申请执行人', '被执行人']
  }.freeze
  
  # Amount status (金额状态)
  AMOUNT_STATUSES = {
    'pending' => '待判决',
    'awarded' => '已判决',
    'paid' => '已支付',
    'partial_paid' => '部分支付'
  }.freeze
  
  # Case outcome (案件结局)
  CASE_OUTCOMES = {
    'total_win' => '全胜',
    'partial_win' => '部分胜诉',
    'lose' => '败诉',
    'settled' => '调解',
    'withdrawn' => '撤诉'
  }.freeze
  
  # Execution status (执行状态)
  EXECUTION_STATUSES = {
    'executing' => '执行中',
    'terminated' => '终本',
    'settled' => '和解执行',
    'completed' => '执行完毕'
  }.freeze
  
  # Associations
  belongs_to :company
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :work_logs, dependent: :destroy
  has_many :case_team_members, dependent: :destroy
  has_many :team_lawyers, through: :case_team_members, source: :lawyer_account
  has_many :case_notifications, dependent: :destroy
  has_many :case_progress_events, dependent: :destroy
  has_many :case_weekly_reports, dependent: :destroy
  has_many :case_questions, dependent: :destroy
  has_many :case_relations_as_from, class_name: 'CaseRelation', foreign_key: 'from_case_id', dependent: :destroy
  has_many :case_relations_as_to, class_name: 'CaseRelation', foreign_key: 'to_case_id', dependent: :destroy
  has_many :related_cases_from, through: :case_relations_as_from, source: :to_case
  has_many :related_cases_to, through: :case_relations_as_to, source: :from_case
  has_many :case_series_memberships, dependent: :destroy
  has_many :case_series, through: :case_series_memberships
  
  # 多委托人关联
  has_many :case_clients, dependent: :destroy
  has_many :client_companies, through: :case_clients, source: :company
  
  # 合同关联（双向）
  has_many :related_contracts, class_name: 'Contract', foreign_key: 'related_case_id'
  
  # Nested attributes
  accepts_nested_attributes_for :case_team_members, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :case_clients, allow_destroy: true, reject_if: :all_blank
  
  # Active Storage attachments
  has_many_attached :attachments # 案件通用附件
  has_many_attached :filing_attachments # 立案日期附件(受理通知书)
  has_many_attached :hearing_attachments # 开庭时间附件(传票)
  has_many_attached :judgement_attachments # 领取判决书附件(判决书扫描件)
  has_many_attached :archived_attachments # 归档日期附件
  has_many_attached :property_preservation_attachments # 财产保全附件
  has_one_attached :agency_contract # 民事委托代理合同
  has_one_attached :lawyer_fee_invoice # 律师费发票
  
  # Serialize JSON fields
  # 以下字段已迁移到 PostgreSQL jsonb 类型（见 migrate_case_json_columns_to_jsonb.rb）
  # jsonb 列由 Rails 自动处理 Hash/Array 序列化，无需 serialize 声明
  # serialize :property_preservation_history, coder: JSON  # migrated to jsonb
  # serialize :third_parties, coder: JSON                  # migrated to jsonb
  # serialize :claims, coder: JSON                         # migrated to jsonb
  # serialize :judgement_result, coder: JSON               # migrated to jsonb
  # serialize :execution_measures, coder: JSON             # migrated to jsonb
  
  # Validations
  validates :name, presence: true
  validates :case_number, presence: true, uniqueness: { scope: :company_id }, unless: -> { status == 'preparing' }
  validates :case_type, presence: true
  validates :status, presence: true, inclusion: { in: %w[preparing filed trial judged execution settled closed] }
  validates :stage, inclusion: { in: %w[arbitration first_trial second_trial execution retrial resume_execution], allow_nil: true }
  validates :filing_at, presence: true, unless: -> { status == 'preparing' }
  
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
  
  # Validate all attachment types
  validate :validate_all_attachments
  
  private
  
  def validate_all_attachments
    validate_attachment_collection(:attachments, "案件材料")
    validate_attachment_collection(:filing_attachments, "受理通知书")
    validate_attachment_collection(:hearing_attachments, "传票")
    validate_attachment_collection(:judgement_attachments, "判决书")
    validate_attachment_collection(:archived_attachments, "归档文件")
    validate_attachment_collection(:property_preservation_attachments, "财产保全文件")
    validate_single_attachment(:agency_contract, "民事委托代理合同")
    validate_single_attachment(:lawyer_fee_invoice, "律师费发票")
  end
  
  def validate_attachment_collection(attachment_name, display_name)
    collection = send(attachment_name)
    return unless collection.attached?
    
    collection.each do |attachment|
      if attachment.byte_size > MAX_FILE_SIZE
        errors.add(attachment_name, "#{display_name}文件 #{attachment.filename} 不得大于 40MB")
      end
      
      unless ALLOWED_CONTENT_TYPES.include?(attachment.content_type)
        errors.add(attachment_name, "#{display_name}文件 #{attachment.filename} 格式不支持，仅支持图片、PDF、Word、Excel文件")
      end
    end
  end
  
  def validate_single_attachment(attachment_name, display_name)
    attachment = send(attachment_name)
    return unless attachment.attached?
    
    if attachment.byte_size > MAX_FILE_SIZE
      errors.add(attachment_name, "#{display_name}文件不得大于 40MB")
    end
    
    unless ALLOWED_CONTENT_TYPES.include?(attachment.content_type)
      errors.add(attachment_name, "#{display_name}格式不支持，仅支持图片、PDF、Word、Excel文件")
    end
  end
  
  public
  
  # Scopes
  scope :ordered, -> { order(filing_at: :desc) }
  scope :preparing, -> { where(status: 'preparing') }
  scope :active, -> { where(status: ['filed', 'trial', 'judged', 'execution']) }
  scope :closed, -> { where(status: ['settled', 'closed']) }
  # not_deleted, pending_deletion, deleted scopes 由 SoftDeletable concern 提供

  # 新增高级筛选scopes
  scope :high_value, -> { where('claim_amount >= ?', 1_000_000) }  # 高标的案件（100万以上）
  scope :urgent_cases, -> { where(priority: 'urgent').active }      # 紧急案件
  scope :need_update, -> { where('last_activity_at < ?', 30.days.ago).active }  # 30天未更新
  scope :upcoming_hearings, ->(days = 7) { where('hearing_at > ? AND hearing_at < ?', Time.current, days.to_i.days.from_now) }  # N天内开庭
  scope :overdue_judgements, -> { where(status: 'judged').where('judgement_received_at < ?', 15.days.ago).where.not(status: ['execution', 'settled', 'closed']) }  # 超期未执行
  scope :by_client, ->(company_id) { joins(:case_clients).where(case_clients: { company_id: company_id }) }  # 按委托人筛选
  
  # Status display names（映射由 STATUS_LABELS 常量维护）
  def status_display = display_label(:status, STATUS_LABELS)
  
  # Status badge color helper
  def status_badge_color
    case status
    when 'preparing' then 'warning'   # 黄色 - 准备阶段
    when 'filed' then 'info'          # 蓝色 - 已立案
    when 'trial' then 'danger'        # 红色 - 审理中(紧急)
    when 'judged' then 'primary'      # 主色 - 已判决
    when 'execution' then 'warning'   # 黄色 - 执行中
    when 'settled' then 'success'     # 绿色 - 调解结案
    when 'closed' then 'neutral'      # 灰色 - 已归档
    else 'neutral'
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
  
  # Priority display（PRIORITIES 已含 value→中文，复用 display_label）
  def priority_display = display_label(:priority, PRIORITIES)
  
  # Party role display
  def our_party_role_display
    PARTY_ROLES[our_party_role] || our_party_role
  end
  
  def counterparty_role_display
    PARTY_ROLES[counterparty_role] || counterparty_role
  end
  
  # Lawyer fee payment status display
  def lawyer_fee_payment_status_display
    case lawyer_fee_payment_status
    when 'pending' then '待付款'
    when 'partial' then '部分付款'
    when 'completed' then '已付清'
    else '未设置'
    end
  end
  
  # Calculate pending lawyer fee amount
  def pending_lawyer_fee
    return 0 unless lawyer_fee.present? && lawyer_fee > 0
    pending_amount = lawyer_fee - (lawyer_fee_received || 0)
    [pending_amount, 0].max  # 确保不返回负数
  end
  
  # Calculate lawyer fee collection progress percentage
  def lawyer_fee_collection_progress
    return 0 unless lawyer_fee.present? && lawyer_fee > 0
    return 0 unless lawyer_fee_received.present? && lawyer_fee_received > 0
    ((lawyer_fee_received / lawyer_fee) * 100).round(1)
  end
  
  # Check if invoice information is complete
  def invoice_info_complete?
    lawyer_fee_invoice_issued && 
    lawyer_fee_invoice_number.present? && 
    lawyer_fee_invoice_amount.present? && 
    lawyer_fee_invoice_issued_at.present?
  end
  
  # Dynamic filing label based on stage and party role
  def filing_label
    return '立案日期' if our_party_role.blank?
    
    case stage
    when 'first_trial', 'arbitration'
      our_party_role == '原告' ? '立案日期' : '应诉日期'
    when 'second_trial'
      our_party_role == '上诉人' ? '上诉日期' : '收到上诉状日期'
    when 'retrial'
      our_party_role == '再审申请人' ? '再审申请日期' : '收到再审通知日期'
    when 'execution', 'resume_execution'
      our_party_role == '申请执行人' ? '申请执行日期' : '收到执行通知日期'
    else
      '立案日期'
    end
  end
  
  # Dynamic filing attachment label based on stage and party role
  def filing_attachment_label
    return '受理通知书' if our_party_role.blank?
    
    case stage
    when 'first_trial', 'arbitration'
      our_party_role == '原告' ? '受理通知书' : '应诉通知书'
    when 'second_trial'
      our_party_role == '上诉人' ? '上诉状' : '上诉状副本'
    when 'retrial'
      our_party_role == '再审申请人' ? '再审申请书' : '再审通知书'
    when 'execution', 'resume_execution'
      our_party_role == '申请执行人' ? '执行申请书' : '执行通知书'
    else
      '受理通知书'
    end
  end
  
  # Get available party roles for current stage
  # Returns array of [display_text, value] for options_for_select
  def available_party_roles
    roles_hash = if stage.blank?
      PARTY_ROLES
    else
      role_keys = PARTY_ROLES_BY_STAGE[stage] || PARTY_ROLES.keys
      PARTY_ROLES.select { |k, v| role_keys.include?(k) }
    end
    
    # Convert hash to array format: [['原告/申请人', '原告'], ...]
    roles_hash.map { |key, display| [display, key] }
  end
  
  # 软删除方法由 SoftDeletable concern 提供：
  # - request_deletion_by_employee(employee_user)
  # - confirm_deletion_by_boss(boss_user)
  # - delete_by_boss(boss_user)
  # - deleted?
  # - pending_deletion?

  # 权限判断方法
  
  # 律师是否可以查看案件（团队成员或所有律师都可以查看）
  def can_lawyer_view?(lawyer_account)
    return false unless lawyer_account.is_a?(LawyerAccount)
    # 所有律师都可以查看所有案件
    true
  end
  
  # 律师是否可以编辑案件基本信息（主办律师可以）
  def can_lawyer_edit?(lawyer_account)
    return false unless lawyer_account.is_a?(LawyerAccount)
    is_lead_lawyer?(lawyer_account)
  end
  
  # 律师是否可以管理团队成员（主办律师可以）
  def can_lawyer_manage_team?(lawyer_account)
    return false unless lawyer_account.is_a?(LawyerAccount)
    is_lead_lawyer?(lawyer_account)
  end
  
  # 律师是否可以添加工作大事记（团队成员可以）
  def can_lawyer_add_work_log?(lawyer_account)
    return false unless lawyer_account.is_a?(LawyerAccount)
    has_team_member?(lawyer_account)
  end
  
  # 律师是否可以编辑工作大事记（团队成员可以编辑自己创建的）
  def can_lawyer_edit_work_log?(lawyer_account, work_log)
    return false unless lawyer_account.is_a?(LawyerAccount)
    return false unless has_team_member?(lawyer_account)
    # 主办律师可以编辑所有工作大事记，其他成员只能编辑自己创建的
    is_lead_lawyer?(lawyer_account) || work_log.created_by_id == lawyer_account.id
  end
  
  # 律师是否可以添加律师意见（团队成员可以）
  def can_lawyer_add_comment?(lawyer_account)
    return false unless lawyer_account.is_a?(LawyerAccount)
    has_team_member?(lawyer_account)
  end
  
  # 团队成员相关方法
  
  # 获取主办律师
  def lead_lawyers
    team_lawyers.joins(:case_team_members).where(case_team_members: { role: 'lead_lawyer', case_id: id })
  end
  
  # 获取辅助律师
  def assistant_lawyers
    team_lawyers.joins(:case_team_members).where(case_team_members: { role: 'assistant_lawyer', case_id: id })
  end
  
  # 获取律师助理
  def legal_assistants
    team_lawyers.joins(:case_team_members).where(case_team_members: { role: 'legal_assistant', case_id: id })
  end
  
  # 检查律师是否在团队中
  def has_team_member?(lawyer_account)
    case_team_members.exists?(lawyer_account_id: lawyer_account.id)
  end
  
  # 获取律师在团队中的角色
  def team_role_for(lawyer_account)
    case_team_members.find_by(lawyer_account_id: lawyer_account.id)&.role
  end
  
  # 检查律师是否是主办律师
  def is_lead_lawyer?(lawyer_account)
    case_team_members.exists?(lawyer_account_id: lawyer_account.id, role: 'lead_lawyer')
  end
  
  # 检查律师是否是辅助律师
  def is_assistant_lawyer?(lawyer_account)
    case_team_members.exists?(lawyer_account_id: lawyer_account.id, role: 'assistant_lawyer')
  end
  
  # 检查律师助理是否在团队中
  def is_legal_assistant?(lawyer_account)
    case_team_members.exists?(lawyer_account_id: lawyer_account.id, role: 'legal_assistant')
  end
  
  # 团队人数统计
  def team_size
    case_team_members.count
  end
  
  # 律师人数（不含助理）
  def lawyers_count
    case_team_members.where(role: ['lead_lawyer', 'assistant_lawyer']).count
  end
  
  # 助理人数
  def assistants_count
    case_team_members.where(role: 'legal_assistant').count
  end
  
  # 是否已归档
  def archived?
    archived_at.present?
  end
  
  # 财产保全相关方法
  
  # 获取财产保全历史记录数组
  def property_preservation_records
    property_preservation_history || []
  end
  
  # 添加财产保全历史记录
  def add_property_preservation_record
    return if property_preservation_applied_at.blank? || property_preservation_deadline.blank?
    
    # 获取当前附件的文件名列表
    attachment_filenames = property_preservation_attachments.map(&:filename).map(&:to_s)
    
    # 创建新记录
    new_record = {
      applied_at: property_preservation_applied_at.to_s,
      deadline: property_preservation_deadline.to_s,
      files: attachment_filenames,
      created_at: Time.current.to_s
    }
    
    # 初始化历史记录数组（如果为空）
    current_history = property_preservation_history || []
    
    # 添加新记录到历史
    current_history << new_record
    
    # 更新历史记录
    self.property_preservation_history = current_history
  end
  
  # 检查是否有有效的财产保全
  def has_active_property_preservation?
    property_preservation_deadline.present? && property_preservation_deadline >= Date.current
  end
  
  # 获取财产保全剩余天数
  def property_preservation_days_left
    return nil unless property_preservation_deadline.present?
    (property_preservation_deadline - Date.current).to_i
  end
  
  # 是否需要财产保全到期提醒（37天内）
  def property_preservation_expiring_soon?
    return false unless has_active_property_preservation?
    property_preservation_days_left <= 37
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
  
  # Searchable implementation
  def search_company_id
    company_id
  end
  
  def search_title
    name
  end
  
  def search_content
    [case_number, case_type, court_name, summary, "状态：#{status_display}", stage.present? ? "阶段：#{stage_display}" : nil].compact.join(" ")
  end
  
  def search_category
    "案件"
  end
  
  def search_metadata
    {
      status: status,
      stage: stage,
      case_number: case_number,
      filing_at: filing_at,
      hearing_at: hearing_at
    }
  end
  
  # 上诉/再审期限相关方法
  
  # 计算上诉/再审届满期
  # 根据中国民事诉讼法：
  # - 一审判决：15天上诉期
  # - 二审判决：不能上诉（终审），但可以申请再审（6个月）
  # - 仲裁裁决：不能上诉，可以申请撤销（6个月）
  def appeal_deadline
    return nil unless judgement_received_at.present?
    
    case stage
    when 'first_trial'
      # 一审判决：15天上诉期
      judgement_received_at + 15.days
    when 'second_trial'
      # 二审判决：6个月再审期
      judgement_received_at + 6.months
    when 'arbitration'
      # 仲裁裁决：6个月申请撤销期
      judgement_received_at + 6.months
    else
      # 其他情况默认使用15天
      judgement_received_at + 15.days
    end
  end
  
  # 上诉/再审届满期类型显示名称
  def appeal_deadline_type
    return nil unless judgement_received_at.present?
    
    case stage
    when 'first_trial'
      '上诉期届满'
    when 'second_trial'
      '再审申请期届满'
    when 'arbitration'
      '申请撤销期届满'
    else
      '上诉期届满'
    end
  end
  
  # 是否已过上诉/再审期
  def appeal_deadline_passed?
    return false unless appeal_deadline.present?
    Date.current > appeal_deadline.to_date
  end
  
  # 距离上诉/再审期届满还有多少天
  def days_until_appeal_deadline
    return nil unless appeal_deadline.present?
    (appeal_deadline.to_date - Date.current).to_i
  end
  
  # 是否需要显示上诉/再审期提醒（已领取判决书且未过期）
  def show_appeal_deadline_reminder?
    judgement_received_at.present? && !appeal_deadline_passed?
  end
  
  # 上诉/再审期提醒级别（用于颜色显示）
  # 返回：:danger (剩余3天内), :warning (剩余7天内), :info (其他)
  def appeal_deadline_urgency
    return :info unless show_appeal_deadline_reminder?
    
    days = days_until_appeal_deadline
    return :danger if days <= 3
    return :warning if days <= 7
    :info
  end
  
  # 获取有效的上诉期限日期（优先使用手动设置的日期，否则使用自动计算的日期）
  def effective_appeal_deadline
    appeal_deadline_date.presence || appeal_deadline
  end
  
  # 是否手动设置了上诉期限
  def appeal_deadline_manually_set?
    appeal_deadline_date.present?
  end
  
  # 上诉期限是否已过期（基于有效日期）
  def effective_appeal_deadline_passed?
    return false unless effective_appeal_deadline.present?
    Date.current > effective_appeal_deadline.to_date
  end
  
  # 距离有效上诉期限还有多少天
  def days_until_effective_appeal_deadline
    return nil unless effective_appeal_deadline.present?
    (effective_appeal_deadline.to_date - Date.current).to_i
  end
  
  # ==============================================
  # 新增功能：标的额相关方法
  # ==============================================
  
  # 金额状态显示
  def amount_status_display
    AMOUNT_STATUSES[amount_status] || amount_status
  end
  
  # 标的额格式化显示（带万元单位）
  def formatted_claim_amount
    return nil unless claim_amount.present?
    if claim_amount >= 10000
      "#{(claim_amount / 10000.0).round(2)}万元"
    else
      "#{claim_amount.to_i}元"
    end
  end
  
  # 判决金额格式化显示
  def formatted_awarded_amount
    return nil unless awarded_amount.present?
    if awarded_amount >= 10000
      "#{(awarded_amount / 10000.0).round(2)}万元"
    else
      "#{awarded_amount.to_i}元"
    end
  end
  
  # 胜诉率计算（判决金额/诉讼标的额）
  def win_rate
    return nil unless claim_amount.present? && claim_amount > 0 && awarded_amount.present?
    ((awarded_amount / claim_amount) * 100).round(2)
  end
  
  # 是否高标的案件（100万以上）
  def high_value?
    claim_amount.present? && claim_amount >= 1_000_000
  end
  
  # ==============================================
  # 新增功能：案件结局相关方法
  # ==============================================
  
  # 案件结局显示
  def case_outcome_display
    CASE_OUTCOMES[case_outcome] || case_outcome
  end
  
  # 案件结局颜色
  def case_outcome_color
    case case_outcome
    when 'total_win' then 'success'
    when 'partial_win' then 'info'
    when 'lose' then 'danger'
    when 'settled' then 'primary'
    when 'withdrawn' then 'neutral'
    else 'neutral'
    end
  end
  
  # ==============================================
  # 新增功能：诉讼请求相关方法
  # ==============================================
  
  # 获取诉讼请求数组
  def claims_list
    claims || []
  end
  
  # 获取判决结果数组
  def judgement_result_list
    judgement_result || []
  end
  
  # ==============================================
  # 新增功能：执行阶段相关方法
  # ==============================================
  
  # 执行状态显示
  def execution_status_display
    EXECUTION_STATUSES[execution_status] || execution_status
  end
  
  # 执行状态颜色
  def execution_status_color
    case execution_status
    when 'executing' then 'info'
    when 'terminated' then 'danger'
    when 'settled' then 'success'
    when 'completed' then 'success'
    else 'neutral'
    end
  end
  
  # 获取执行措施数组
  def execution_measures_list
    execution_measures || []
  end
  
  # 已执行金额格式化
  def formatted_executed_amount
    return nil unless executed_amount.present?
    if executed_amount >= 10000
      "#{(executed_amount / 10000.0).round(2)}万元"
    else
      "#{executed_amount.to_i}元"
    end
  end
  
  # 执行进度百分比
  def execution_progress
    return 0 unless awarded_amount.present? && awarded_amount > 0 && executed_amount.present?
    ((executed_amount / awarded_amount) * 100).round(2)
  end
  
  # ==============================================
  # 新增功能：多委托人相关方法
  # ==============================================
  
  # 获取主委托人
  def primary_client
    case_clients.primary.first&.company
  end
  
  # 获取共同委托人列表
  def co_client_list
    case_clients.co_clients.ordered.map(&:company)
  end
  
  # 委托人总数
  def clients_count
    case_clients.count
  end
  
  # 是否多委托人案件
  def multiple_clients?
    clients_count > 1
  end
  
  # 所有委托人名称字符串（逗号分隔）
  def all_clients_names
    client_companies.pluck(:name).join('、')
  end
  
  # ==============================================
  # 新增功能：第三人信息相关方法
  # ==============================================
  
  # 获取第三人数组
  def third_parties_list
    third_parties || []
  end
  
  # 是否有第三人
  def has_third_parties?
    third_parties_list.any?
  end
end
