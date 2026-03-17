class LawyerTeam < ApplicationRecord
  # Associations
  belongs_to :leader, class_name: 'LawyerAccount', optional: true
  has_many :lawyer_accounts, foreign_key: 'lawyer_team_id', dependent: :nullify
  has_many :business_team_ownerships, dependent: :destroy
  
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true, format: { with: /\A[A-Z_]+\z/, message: '只能包含大写字母和下划线' }
  validates :data_isolation_level, presence: true, inclusion: { in: %w[strict flexible] }
  validates :status, presence: true, inclusion: { in: %w[active archived] }
  
  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :archived, -> { where(status: 'archived') }
  scope :ordered, -> { order(created_at: :desc) }
  
  # Status methods
  def active?
    status == 'active'
  end
  
  def archived?
    status == 'archived'
  end
  
  # Archive team
  def archive!
    update!(status: 'archived')
  end
  
  # Activate team
  def activate!
    update!(status: 'active')
  end
  
  # Data isolation level display
  def data_isolation_level_display
    case data_isolation_level
    when 'strict' then '严格隔离'
    when 'flexible' then '灵活隔离'
    end
  end
  
  # Status display
  def status_display
    case status
    when 'active' then '正常'
    when 'archived' then '已归档'
    end
  end
end
