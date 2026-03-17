module CaseFilterable
  extend ActiveSupport::Concern
  
  included do
    # 高级筛选
    scope :filter_by_status, ->(statuses) { 
      where(status: statuses) if statuses.present? 
    }
    
    scope :filter_by_stage, ->(stages) { 
      where(stage: stages) if stages.present? 
    }
    
    scope :filter_by_case_type, ->(types) { 
      where(case_type: types) if types.present? 
    }
    
    scope :filter_by_priority, ->(priorities) { 
      where(priority: priorities) if priorities.present? 
    }
    
    scope :filter_by_company, ->(company_id) { 
      where(company_id: company_id) if company_id.present? 
    }
    
    scope :filter_by_team_member, ->(lawyer_id) {
      joins(:case_team_members).where(case_team_members: { lawyer_account_id: lawyer_id }).distinct if lawyer_id.present?
    }
    
    scope :filter_by_lead_lawyer, ->(lawyer_id) {
      joins(:case_team_members).where(case_team_members: { lawyer_account_id: lawyer_id, role: 'lead_lawyer' }).distinct if lawyer_id.present?
    }
    
    scope :filter_by_date_range, ->(field, start_date, end_date) {
      where("#{field} BETWEEN ? AND ?", start_date, end_date) if start_date.present? && end_date.present?
    }
    
    scope :upcoming_hearings, ->(days) {
      where('hearing_at BETWEEN ? AND ?', Time.current, days.to_i.days.from_now) if days.present?
    }
    
    scope :appeal_deadline_approaching, ->(days) {
      where('appeal_deadline_date BETWEEN ? AND ?', Date.today, days.to_i.days.from_now) if days.present?
    }
    
    # 财产保全筛选
    scope :with_property_preservation, -> {
      where.not(property_preservation_deadline: nil)
    }
    
    scope :with_active_property_preservation, -> {
      where('property_preservation_deadline >= ?', Date.current)
    }
    
    # 全文搜索
    scope :search_by_keyword, ->(keyword) {
      return all if keyword.blank?
      
      where(
        "name ILIKE :keyword OR case_number ILIKE :keyword OR court_name ILIKE :keyword OR summary ILIKE :keyword",
        keyword: "%#{keyword}%"
      )
    }
    
    # 智能排序
    scope :order_by_field, ->(field, direction = 'desc') {
      direction = direction.to_s.downcase == 'asc' ? 'asc' : 'desc'
      case field.to_s
      when 'updated_at', 'last_activity'
        order(last_activity_at: direction, updated_at: direction)
      when 'filing_at', 'filing_date'
        order(Arel.sql("filing_at #{direction} NULLS LAST"))
      when 'hearing_at', 'hearing_date'
        order(Arel.sql("hearing_at #{direction} NULLS LAST"))
      when 'property_preservation_deadline', 'property_preservation'
        order(Arel.sql("property_preservation_deadline ASC NULLS LAST"))
      when 'priority'
        order(Arel.sql("CASE priority WHEN 'urgent' THEN 1 WHEN 'high' THEN 2 WHEN 'normal' THEN 3 WHEN 'low' THEN 4 END #{direction}"))
      when 'name'
        order(name: direction)
      else
        order(filing_at: direction)
      end
    }
  end
  
  class_methods do
    def apply_filters(params)
      scope = all
      
      scope = scope.filter_by_status(params[:statuses]) if params[:statuses].present?
      scope = scope.filter_by_stage(params[:stages]) if params[:stages].present?
      scope = scope.filter_by_case_type(params[:case_types]) if params[:case_types].present?
      scope = scope.filter_by_priority(params[:priorities]) if params[:priorities].present?
      scope = scope.filter_by_company(params[:company_id]) if params[:company_id].present? && params[:company_id] != 'all'
      scope = scope.filter_by_team_member(params[:team_member_id]) if params[:team_member_id].present?
      scope = scope.filter_by_lead_lawyer(params[:lead_lawyer_id]) if params[:lead_lawyer_id].present?
      scope = scope.upcoming_hearings(params[:hearing_days]) if params[:hearing_days].present?
      scope = scope.appeal_deadline_approaching(params[:appeal_days]) if params[:appeal_days].present?
      scope = scope.with_property_preservation if params[:has_property_preservation] == '1'
      scope = scope.with_active_property_preservation if params[:has_property_preservation] == 'active'
      scope = scope.search_by_keyword(params[:keyword]) if params[:keyword].present?
      
      # 日期范围筛选
      if params[:filed_from].present? && params[:filed_to].present?
        scope = scope.filter_by_date_range(:filing_at, params[:filed_from], params[:filed_to])
      end
      
      # 排序
      scope = scope.order_by_field(params[:sort_by] || 'updated_at', params[:sort_direction] || 'desc')
      
      scope
    end
  end
end
