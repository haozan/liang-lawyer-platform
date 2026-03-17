class CaseSeries < ApplicationRecord
  belongs_to :company
  belongs_to :created_by, polymorphic: true
  
  has_many :case_series_memberships, dependent: :destroy
  has_many :cases, through: :case_series_memberships
  
  validates :name, presence: true
  
  scope :ordered, -> { order(created_at: :desc) }
  
  def add_case(case_record, position: nil)
    case_series_memberships.create!(
      case: case_record,
      position: position || (case_series_memberships.maximum(:position) || 0) + 1
    )
  end
  
  def stats
    {
      total_count: cases.count,
      closed_count: cases.where(status: 'closed').count,
      active_count: cases.where(status: ['investigating', 'in_court']).count,
      pending_count: cases.where(status: 'pending').count
    }
  end
end
