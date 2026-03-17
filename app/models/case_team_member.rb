class CaseTeamMember < ApplicationRecord
  # Associations
  belongs_to :case
  belongs_to :lawyer_account
  
  # Validations
  validates :case_id, presence: true, on: :update
  validates :lawyer_account_id, presence: true
  validates :role, presence: true, inclusion: { 
    in: %w[lead_lawyer assistant_lawyer legal_assistant], 
    message: '必须是主办律师、辅助律师或律师助理' 
  }
  validates :lawyer_account_id, uniqueness: { 
    scope: :case_id, 
    message: '该律师/助理已在团队中' 
  }, on: :update
  
  # Custom validation: role must match lawyer_account role
  validate :role_matches_lawyer_account_role
  
  # Scopes
  scope :ordered, -> { order(joined_at: :desc) }
  scope :lead_lawyers, -> { where(role: 'lead_lawyer') }
  scope :assistant_lawyers, -> { where(role: 'assistant_lawyer') }
  scope :legal_assistants, -> { where(role: 'legal_assistant') }
  
  # Set default joined_at before creation
  before_create :set_joined_at
  
  # Role display names
  def role_display
    case role
    when 'lead_lawyer' then '主办律师'
    when 'assistant_lawyer' then '辅助律师'
    when 'legal_assistant' then '律师助理'
    end
  end
  
  # Check if this member is a lead lawyer
  def lead_lawyer?
    role == 'lead_lawyer'
  end
  
  # Check if this member is an assistant lawyer
  def assistant_lawyer?
    role == 'assistant_lawyer'
  end
  
  # Check if this member is a legal assistant
  def legal_assistant?
    role == 'legal_assistant'
  end
  
  private
  
  def set_joined_at
    self.joined_at ||= Time.current
  end
  
  def role_matches_lawyer_account_role
    return if lawyer_account.nil?
    
    case role
    when 'lead_lawyer', 'assistant_lawyer'
      unless lawyer_account.lawyer?
        errors.add(:role, '只有律师可以担任主办律师或辅助律师')
      end
    when 'legal_assistant'
      unless lawyer_account.assistant?
        errors.add(:role, '只有律师助理可以担任该角色')
      end
    end
  end
end
