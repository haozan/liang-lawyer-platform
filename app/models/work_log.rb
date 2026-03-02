class WorkLog < ApplicationRecord
  belongs_to :case
  belongs_to :submitter, polymorphic: true, optional: true # 支持 LawyerAccount 和 CompanyUser
  has_many_attached :attachments # 工作大事记附件
  
  # Validations
  validates :date, presence: true
  validates :title, presence: true
  validates :content, presence: true
  
  # Scopes
  scope :ordered, -> { order(date: :desc, created_at: :desc) }
  
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
end
