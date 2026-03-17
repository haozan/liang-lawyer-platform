class CaseRelation < ApplicationRecord
  belongs_to :from_case, class_name: 'Case'
  belongs_to :to_case, class_name: 'Case'
  
  validates :from_case_id, presence: true
  validates :to_case_id, presence: true
  validates :relation_type, presence: true, inclusion: { 
    in: %w[parent child related series appeal retrial] 
  }
  
  RELATION_TYPES = {
    'parent' => '原案',
    'child' => '派生案件',
    'related' => '相关案件',
    'series' => '系列案件',
    'appeal' => '上诉案件',
    'retrial' => '再审案件'
  }.freeze
  
  def relation_display
    RELATION_TYPES[relation_type] || relation_type
  end
end
