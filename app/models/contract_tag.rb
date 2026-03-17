class ContractTag < ApplicationRecord
  # Associations
  belongs_to :company
  has_many :contract_taggings, foreign_key: :tag_id, dependent: :destroy
  has_many :contracts, through: :contract_taggings
  
  # Validations
  validates :name, presence: true, uniqueness: { scope: :company_id }
  validates :color, presence: true, format: { with: /\A#[0-9A-F]{6}\z/i, message: "必须是有效的颜色代码" }
  
  # Scopes
  scope :ordered, -> { order(:name) }
  
  # Class method to get predefined colors
  def self.predefined_colors
    [
      { name: '蓝色', value: '#3B82F6' },
      { name: '绿色', value: '#10B981' },
      { name: '黄色', value: '#F59E0B' },
      { name: '红色', value: '#EF4444' },
      { name: '紫色', value: '#8B5CF6' },
      { name: '粉色', value: '#EC4899' },
      { name: '青色', value: '#06B6D4' },
      { name: '灰色', value: '#6B7280' }
    ]
  end
end
