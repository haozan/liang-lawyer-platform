class Case < ApplicationRecord
  include CaseFilterable
  include SoftDeletable
  include DisplayLabels

  # === 常量 ===
  STATUS_LABELS = {
    'preparing'  => '准备立案',
    'filed'      => '已立案待审',
    'trial'      => '审理中',
    'judged'     => '已判决',
    'execution'  => '执行中',
    'settled'    => '调解结案',
    'closed'     => '已归档'
  }.freeze

  PRIORITIES = {
    'urgent' => '紧急',
    'high' => '高',
    'normal' => '普通',
    'low' => '低'
  }.freeze

  PARTY_ROLES = {
    '原告' => '原告/申请人',
    '被告' => '被告/被申请人',
    '上诉人' => '上诉人',
    '被上诉人' => '被上诉人',
    '再审申请人' => '再审申请人',
    '再审被申请人' => '再审被申请人',
    '申请执行人' => '申请执行人',
    '被执行人' => '被执行人'
  }.freeze

  STAGES = %w[arbitration first_trial second_trial execution retrial resume_execution].freeze

  # === 关联 ===
  belongs_to :company
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :work_logs, dependent: :destroy
  has_many :case_team_members, dependent: :destroy
  has_many :team_lawyers, through: :case_team_members, source: :lawyer_account
  has_many_attached :attachments

  accepts_nested_attributes_for :case_team_members, allow_destroy: true, reject_if: :all_blank

  # === 验证 ===
  validates :name, presence: true
  validates :case_type, presence: true
  validates :status, presence: true, inclusion: { in: %w[preparing filed trial judged execution settled closed] }
  validates :stage, inclusion: { in: STAGES, allow_nil: true }

  # === Scopes ===
  scope :ordered, -> { order(created_at: :desc) }
  scope :active, -> { where(status: %w[filed trial judged execution]) }
  scope :closed, -> { where(status: %w[settled closed]) }
  scope :upcoming_hearings, ->(days = 7) { where('hearing_at > ? AND hearing_at < ?', Time.current, days.to_i.days.from_now) }
  scope :preservation_expiring, ->(days = 40) { where('property_preservation_deadline > ? AND property_preservation_deadline < ?', Date.current, days.to_i.days.from_now) }

  # === 显示方法 ===
  def status_display = display_label(:status, STATUS_LABELS)
  def priority_display = display_label(:priority, PRIORITIES)

  def status_badge_color
    case status
    when 'preparing' then 'warning'
    when 'filed' then 'info'
    when 'trial' then 'danger'
    when 'judged' then 'primary'
    when 'execution' then 'warning'
    when 'settled' then 'success'
    when 'closed' then 'neutral'
    else 'neutral'
    end
  end

  def stage_display
    return nil if stage.blank?
    { 'arbitration' => '仲裁', 'first_trial' => '一审', 'second_trial' => '二审',
      'execution' => '执行', 'retrial' => '再审', 'resume_execution' => '恢复执行' }[stage]
  end

  def our_party_role_display
    PARTY_ROLES[our_party_role] || our_party_role
  end

  # === 三个时间提醒 ===

  # 1. 开庭时间倒计时
  def days_until_hearing
    return nil unless hearing_at.present?
    (hearing_at.to_date - Date.current).to_i
  end

  def hearing_urgent?
    days_until_hearing.present? && days_until_hearing <= 3 && days_until_hearing >= 0
  end

  # 2. 财产保全续封倒计时（到期前40天开始提醒）
  def days_until_preservation_deadline
    return nil unless property_preservation_deadline.present?
    (property_preservation_deadline - Date.current).to_i
  end

  def preservation_expiring_soon?
    return false unless property_preservation_deadline.present?
    days_left = days_until_preservation_deadline
    days_left.present? && days_left <= 40 && days_left >= 0
  end

  # 3. 上诉期满倒计时
  def effective_appeal_deadline
    # 优先使用手动设置的日期，否则自动计算
    appeal_deadline_date.presence || calculated_appeal_deadline
  end

  def days_until_appeal_deadline
    return nil unless effective_appeal_deadline.present?
    (effective_appeal_deadline.to_date - Date.current).to_i
  end

  def appeal_deadline_passed?
    return false unless effective_appeal_deadline.present?
    Date.current > effective_appeal_deadline.to_date
  end

  def appeal_deadline_urgency
    days = days_until_appeal_deadline
    return :info if days.nil?
    return :danger if days <= 3
    return :warning if days <= 7
    :info
  end

  # === 团队成员方法 ===

  def lead_lawyers
    team_lawyers.joins(:case_team_members).where(case_team_members: { role: 'lead_lawyer', case_id: id })
  end

  def assistant_lawyers
    team_lawyers.joins(:case_team_members).where(case_team_members: { role: 'assistant_lawyer', case_id: id })
  end

  def has_team_member?(lawyer_account)
    case_team_members.exists?(lawyer_account_id: lawyer_account.id)
  end

  def is_lead_lawyer?(lawyer_account)
    case_team_members.exists?(lawyer_account_id: lawyer_account.id, role: 'lead_lawyer')
  end

  def team_size
    case_team_members.count
  end

  # === 权限方法（简化） ===

  # 所有律师都能看
  def can_lawyer_view?(_lawyer_account) = true

  # 主办律师能编辑
  def can_lawyer_edit?(lawyer_account)
    lawyer_account.is_a?(LawyerAccount) && is_lead_lawyer?(lawyer_account)
  end

  # 企业用户只能看自己公司的案件
  def can_company_user_view?(user)
    user.is_a?(CompanyUser) && user.company_id == company_id
  end

  # 企业用户不能编辑
  def can_company_user_edit?(_user) = false

  # === 访问控制 ===
  def self.accessible_by(lawyer_account)
    # 律师可以看到所有案件
    all
  end

  private

  def calculated_appeal_deadline
    return nil unless judgement_received_at.present?
    case stage
    when 'first_trial'
      judgement_received_at + 15.days
    when 'second_trial', 'arbitration'
      judgement_received_at + 6.months
    else
      judgement_received_at + 15.days
    end
  end
end
