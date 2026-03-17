class CaseQuestion < ApplicationRecord
  belongs_to :case
  belongs_to :asker, polymorphic: true
  belongs_to :answerer, polymorphic: true, optional: true
  
  validates :question, presence: true
  
  scope :unresolved, -> { where(is_resolved: false) }
  scope :resolved, -> { where(is_resolved: true) }
  scope :unanswered, -> { where(answer: nil) }
  scope :answered, -> { where.not(answer: nil) }
  scope :ordered, -> { order(created_at: :desc) }
  
  def mark_as_resolved!
    update!(is_resolved: true)
  end
  
  def asker_name
    asker.try(:name) || '未知用户'
  end
  
  def answerer_name
    answerer.try(:name) || nil
  end
end
