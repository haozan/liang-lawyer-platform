class LawyerAccount < ApplicationRecord
  has_secure_password
  
  # Concerns
  include LockableAccount
  
  # Associations
  belongs_to :lawyer_team, optional: true
  has_many :led_teams, class_name: 'LawyerTeam', foreign_key: 'leader_id', dependent: :nullify
  has_many :mentioned_issues, class_name: 'MajorIssue', foreign_key: 'mentioned_lawyer_id'
  has_many :case_team_members, dependent: :destroy
  has_many :cases, through: :case_team_members
  has_many :case_filters, as: :user, dependent: :destroy
  has_many :lawyer_business_accesses, foreign_key: 'lawyer_id', dependent: :destroy
  has_many :authorized_accesses, class_name: 'LawyerBusinessAccess', foreign_key: 'authorized_by_id', dependent: :nullify
  has_many :data_access_logs, foreign_key: 'lawyer_id', dependent: :destroy
  
  # Validations
  validates :name, presence: true
  validates :phone, presence: true, uniqueness: true, format: { with: /\A1[3-9]\d{9}\z/, message: '必须是有效的中国手机号码' }
  validates :password, length: { minimum: 6 }, allow_nil: true
  validates :role, presence: true, inclusion: { in: %w[assistant lawyer senior_lawyer team_leader super_admin] }
  
  # Normalize phone before saving
  before_save :normalize_phone
  
  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :lawyers, -> { where(role: ['lawyer', 'senior_lawyer', 'team_leader']) }
  scope :assistants, -> { where(role: 'assistant') }
  scope :in_team, ->(team_id) { where(lawyer_team_id: team_id) }
  
  # Role checking methods
  def lawyer?
    role.in?(['lawyer', 'senior_lawyer', 'team_leader', 'super_admin'])
  end
  
  def assistant?
    role == 'assistant'
  end
  
  def super_admin?
    role == 'super_admin'
  end
  
  def team_leader?
    role == 'team_leader'
  end
  
  def senior_lawyer?
    role == 'senior_lawyer'
  end
  
  # Check if lawyer is team leader of a specific team
  def team_leader_of?(team)
    return false unless team.present?
    team.leader_id == id
  end
  
  # Display name for comments
  def display_name
    role_text = case role
    when 'super_admin' then '管理员'
    when 'team_leader' then '团队负责人'
    when 'senior_lawyer' then '资深律师'
    when 'lawyer' then '律师'
    when 'assistant' then '律师助理'
    else '律师'
    end
    "#{name}（#{role_text}）"
  end
  
  # Role display
  def role_display
    case role
    when 'super_admin' then '超级管理员'
    when 'team_leader' then '团队负责人'
    when 'senior_lawyer' then '资深律师'
    when 'lawyer' then '律师'
    when 'assistant' then '律师助理'
    else role
    end
  end
  
  private
  
  def normalize_phone
    self.phone = phone.to_s.strip if phone.present?
  end
end
