class CaseClient < ApplicationRecord
  # 角色常量
  ROLES = {
    'primary_client' => '主委托人',
    'co_client' => '共同委托人',
    'third_party' => '第三人'
  }.freeze
  
  # Associations
  belongs_to :case
  belongs_to :company
  
  # Validations
  validates :case_id, uniqueness: { scope: :company_id, message: "该委托人已经添加到此案件" }
  validates :role, presence: true, inclusion: { in: ROLES.keys }
  
  # Scopes
  scope :ordered, -> { order(position: :asc, created_at: :asc) }
  scope :primary, -> { where(role: 'primary_client') }
  scope :co_clients, -> { where(role: 'co_client') }
  scope :third_parties, -> { where(role: 'third_party') }
  
  # 角色显示名称
  def role_display
    ROLES[role] || role
  end
  
  # 是否是主委托人
  def primary?
    role == 'primary_client'
  end
end
