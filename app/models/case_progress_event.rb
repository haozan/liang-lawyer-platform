class CaseProgressEvent < ApplicationRecord
  belongs_to :case
  
  validates :event_type, presence: true
  validates :title, presence: true
  validates :event_date, presence: true
  
  scope :ordered, -> { order(event_date: :desc, event_time: :desc, created_at: :desc) }
  scope :milestones, -> { where(is_milestone: true) }
  scope :automated, -> { where(is_automated: true) }
  scope :manual, -> { where(is_automated: false) }
  scope :by_type, ->(type) { where(event_type: type) if type.present? }
  scope :date_range, ->(start_date, end_date) { where(event_date: start_date..end_date) }
end
