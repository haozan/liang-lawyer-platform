class CaseWeeklyReport < ApplicationRecord
  belongs_to :case
  
  validates :week_start_date, presence: true
  validates :week_end_date, presence: true
  
  scope :ordered, -> { order(week_start_date: :desc) }
  scope :auto_generated, -> { where(is_auto_generated: true) }
  scope :manual, -> { where(is_auto_generated: false) }
  
  def week_range
    "#{week_start_date.strftime('%Y-%m-%d')} ~ #{week_end_date.strftime('%Y-%m-%d')}"
  end
end
