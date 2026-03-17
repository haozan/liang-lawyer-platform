class SavedFilter < ApplicationRecord
  # Associations
  belongs_to :user, polymorphic: true
  
  # Validations
  validates :name, presence: true
  validates :filterable_type, presence: true
  validates :user_type, presence: true
  validates :user_id, presence: true
  
  # Scopes
  scope :for_user, ->(user) { where(user_type: user.class.name, user_id: user.id) }
  scope :for_filterable, ->(type) { where(filterable_type: type) }
  scope :defaults, -> { where(is_default: true) }
  
  # Callbacks
  before_save :ensure_single_default, if: :is_default?
  
  private
  
  def ensure_single_default
    # If this filter is being set as default, unset all other defaults for the same user and filterable_type
    SavedFilter.where(
      user_type: user_type,
      user_id: user_id,
      filterable_type: filterable_type,
      is_default: true
    ).where.not(id: id).update_all(is_default: false)
  end
end
