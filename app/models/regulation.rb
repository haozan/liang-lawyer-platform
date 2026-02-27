class Regulation < ApplicationRecord
  # Associations
  belongs_to :company
  has_many :comments, as: :commentable, dependent: :destroy
  has_one_attached :file
  
  # Validations
  validates :name, presence: true
  validates :file, presence: true
  
  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :pending_lawyer_review, -> { where(reviewed_by_lawyer: false) }
  scope :new_files, -> { where('created_at >= ?', 3.days.ago) }
  
  # Lawyer review methods
  def needs_lawyer_review?
    !reviewed_by_lawyer
  end
  
  def overdue_for_review?
    return false if reviewed_by_lawyer
    created_at < 3.days.ago
  end
  
  def overdue_days
    return 0 if reviewed_by_lawyer || created_at >= 3.days.ago
    ((Time.current - created_at) / 1.day).to_i - 3
  end
  
  # Priority: 0=高优先级, 1=中优先级, 2=低优先级
  def lawyer_review_priority
    if created_at >= 3.days.ago && !reviewed_by_lawyer
      2 # 低优先级：新上传的规章制度
    else
      2
    end
  end
end
