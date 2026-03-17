class AnnouncementGroup < ApplicationRecord
  # Validations
  validates :group_key, presence: true, uniqueness: true
  validates :group_name, presence: true
  validates :priority, presence: true, numericality: { only_integer: true }
  
  # Scopes
  scope :ordered, -> { order(priority: :desc) }
  scope :active, -> { where.not(group_key: 'other') }
  
  # 公告类型到分组的映射
  TYPE_TO_GROUP = {
    'hearing' => 'hearing_related',                          # 开庭提醒 → 开庭相关
    'judgement_collection' => 'hearing_related',             # 待领取判决书 → 开庭相关
    'contract_review' => 'review_tasks',                     # 待审查合同 → 审查待办
    'major_issue_review' => 'review_tasks',                  # 待答复重大事项 → 审查待办
    'reconciliation_upload_pending' => 'review_tasks',       # 待上传对账单（企业主） → 审查待办
    'reconciliation_review_pending' => 'review_tasks',       # 待审查对账单（律师） → 审查待办
    'reconciliation_overdue' => 'review_tasks',              # 待上传对账单（旧）→ 审查待办（向后兼容）
    'contract_expiry' => 'expiry_alerts',                    # 合同到期 → 到期提醒
    'custom' => 'other'                                      # 自定义公告 → 其他提醒
  }.freeze
  
  # 根据公告类型获取分组
  def self.group_for_type(announcement_type)
    group_key = TYPE_TO_GROUP[announcement_type] || 'other'
    find_by(group_key: group_key) || find_by(group_key: 'other')
  end
  
  # 获取分组的显示颜色类
  def text_color_class
    "text-#{color_class}-600"
  end
  
  def bg_color_class
    "bg-#{color_class}-50"
  end
  
  def border_color_class
    "border-#{color_class}-500"
  end
  
  def hover_bg_color_class
    "hover:bg-#{color_class}-100"
  end
  
  # 获取分组内的公告数量
  def announcement_count_for(announcements)
    announcements.count { |a| self.class.group_for_type(a[:announcement_type])&.id == id }
  end
end
