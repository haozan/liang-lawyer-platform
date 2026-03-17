class CaseStatisticsService < ApplicationService
  def initialize(scope: Case.all, lawyer: nil, company: nil, date_range: nil)
    @scope = scope
    @lawyer = lawyer
    @company = company
    @date_range = date_range || (1.year.ago..Date.today)
  end
  
  def call
    {
      overview: overview_stats,
      case_type_distribution: case_type_distribution,
      status_distribution: status_distribution,
      stage_distribution: stage_distribution,
      priority_distribution: priority_distribution,
      timeline_stats: timeline_stats,
      performance_metrics: performance_metrics
    }
  end
  
  private
  
  def overview_stats
    {
      total_cases: @scope.count,
      active_cases: @scope.where(status: ['investigating', 'in_court']).count,
      closed_cases: @scope.where(status: 'closed').count,
      pending_cases: @scope.where(status: 'pending').count,
      avg_duration: calculate_avg_duration
    }
  end
  
  def case_type_distribution
    @scope.group(:case_type).count
  end
  
  def status_distribution
    @scope.group(:status).count
  end
  
  def stage_distribution
    @scope.where.not(stage: nil).group(:stage).count
  end
  
  def priority_distribution
    @scope.group(:priority).count
  end
  
  def timeline_stats
    months = []
    current = @date_range.begin.beginning_of_month
    
    while current <= @date_range.end
      months << {
        month: current,
        new_cases: @scope.where(created_at: current.beginning_of_month..current.end_of_month).count,
        closed_cases: @scope.where(closing_at: current.beginning_of_month..current.end_of_month).count
      }
      current = current.next_month
    end
    
    months
  end
  
  def performance_metrics
    return {} unless @lawyer
    
    {
      total_handled: @scope.filter_by_team_member(@lawyer.id).count,
      as_lead_lawyer: @scope.filter_by_lead_lawyer(@lawyer.id).count,
      avg_duration: calculate_avg_duration(@scope.filter_by_team_member(@lawyer.id))
    }
  end
  
  def calculate_avg_duration(scope = @scope)
    closed = scope.where(status: 'closed').where.not(filing_at: nil, closing_at: nil)
    return 0 if closed.count.zero?
    
    durations = closed.map { |c| (c.closing_at - c.filing_at.to_time).to_i / 1.day }
    durations.sum / durations.size
  end
end
