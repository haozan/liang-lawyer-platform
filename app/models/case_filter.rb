class CaseFilter < ApplicationRecord
  belongs_to :user, polymorphic: true
  
  validates :name, presence: true
  validates :filter_params, presence: true
  
  scope :ordered, -> { order(:position, :created_at) }
  scope :default_filter, -> { where(is_default: true) }
  
  # 设置为默认筛选
  def set_as_default!
    transaction do
      # 取消同用户的其他默认筛选
      self.class.where(user: user, is_default: true).where.not(id: id).update_all(is_default: false)
      update!(is_default: true)
    end
  end
  
  # 获取筛选参数的可读描述
  def description
    parts = []
    
    parts << "状态: #{filter_params['statuses']&.join(', ')}" if filter_params['statuses'].present?
    parts << "阶段: #{filter_params['stages']&.join(', ')}" if filter_params['stages'].present?
    parts << "案件类型: #{filter_params['case_types']&.join(', ')}" if filter_params['case_types'].present?
    parts << "优先级: #{filter_params['priorities']&.join(', ')}" if filter_params['priorities'].present?
    parts << "关键词: #{filter_params['keyword']}" if filter_params['keyword'].present?
    
    parts.join(' | ')
  end
end
