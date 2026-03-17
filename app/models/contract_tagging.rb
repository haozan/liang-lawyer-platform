class ContractTagging < ApplicationRecord
  # Associations
  belongs_to :contract
  belongs_to :tag, class_name: 'ContractTag'
  
  # Validations
  validates :contract_id, uniqueness: { scope: :tag_id, message: "合同已有该标签" }
end
