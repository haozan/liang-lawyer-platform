class DataAccessLog < ApplicationRecord
  # Associations
  belongs_to :lawyer, class_name: 'LawyerAccount', foreign_key: 'lawyer_id'
  belongs_to :resource, polymorphic: true, optional: true
  
  # Validations
  validates :lawyer_id, presence: true
  validates :resource_type, presence: true
  validates :resource_id, presence: true
  validates :action, presence: true
  validates :access_method, presence: true
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_lawyer, ->(lawyer_id) { where(lawyer_id: lawyer_id) }
  scope :for_resource, ->(type, id) { where(resource_type: type, resource_id: id) }
  scope :unauthorized_attempts, -> { where(access_method: 'unauthorized_attempt') }
  scope :today, -> { where('created_at >= ?', Time.current.beginning_of_day) }
  scope :this_week, -> { where('created_at >= ?', Time.current.beginning_of_week) }
  scope :this_month, -> { where('created_at >= ?', Time.current.beginning_of_month) }
  
  # Action display
  def action_display
    case action
    when 'show' then '查看'
    when 'edit' then '编辑'
    when 'update' then '更新'
    when 'destroy' then '删除'
    when 'export' then '导出'
    else action
    end
  end
  
  # Access method display
  def access_method_display
    case access_method
    when 'team_owner' then '团队所有者'
    when 'owner' then '业务所有者'
    when 'collaborator' then '协作者'
    when 'viewer' then '查看者'
    when 'authorized' then '被授权'
    when 'cross_team' then '跨团队访问'
    when 'unauthorized_attempt' then '未授权尝试'
    else access_method
    end
  end
  
  # Check if this is an unauthorized attempt
  def unauthorized?
    access_method == 'unauthorized_attempt'
  end
end
