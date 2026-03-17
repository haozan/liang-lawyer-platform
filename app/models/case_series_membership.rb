class CaseSeriesMembership < ApplicationRecord
  belongs_to :case_series
  belongs_to :case
  
  validates :case_series_id, presence: true
  validates :case_id, presence: true
  
  scope :ordered, -> { order(:position) }
end
