class WorkbenchController < ApplicationController
  before_action :require_company_user
  before_action :set_company
  
  def index
    # 获取待办数据
    todo_service = CompanyTodoService.new(company: @company)
    todo_data = todo_service.call
    
    @stats = todo_data[:stats]
    @urgent_items = todo_data[:urgent_items]
    @pending_contracts = todo_data[:pending_contracts]
    @pending_cases = todo_data[:pending_cases]
    @pending_major_issues = todo_data[:pending_major_issues]
    
    # 获取即将到期提醒数据
    @expiring_contracts = expiring_contracts_data
    @upcoming_hearings = upcoming_hearings_data
    @pending_judgement_collections = pending_judgement_collections_data
    @pending_archives = pending_archives_data
    
    # 计算到期项总数
    @expiry_total_count = @expiring_contracts.count + @upcoming_hearings.count + 
                          @pending_judgement_collections.count + @pending_archives.count
  end
  
  private
  
  def set_company
    @company = current_company_user.company
  end
  
  def require_company_user
    unless current_company_user
      redirect_to root_path, alert: '请先登录'
    end
  end
  
  # 即将到期的合同（30天内）
  def expiring_contracts_data
    contracts = @company.contracts.where('end_at BETWEEN ? AND ?', Date.today, 30.days.from_now).order(:end_at)
    
    contracts.map do |contract|
      days_left = (contract.end_at - Date.today).to_i
      urgency = if days_left <= 3
                  :critical
                elsif days_left <= 7
                  :warning
                else
                  :normal
                end
      
      {
        item: contract,
        days_left: days_left,
        urgency: urgency,
        link: contract_path(contract)
      }
    end
  end
  
  # 即将开庭的案件（30天内）
  def upcoming_hearings_data
    cases = @company.cases.not_deleted.where('hearing_at BETWEEN ? AND ?', Time.current, 30.days.from_now).order(:hearing_at)
    
    cases.map do |case_record|
      days_left = ((case_record.hearing_at - Time.current) / 1.day).ceil
      urgency = if days_left <= 3
                  :critical
                elsif days_left <= 7
                  :warning
                else
                  :normal
                end
      
      {
        item: case_record,
        days_left: days_left,
        urgency: urgency,
        link: case_path(case_record)
      }
    end
  end
  
  # 待收取判决书的案件
  def pending_judgement_collections_data
    cases = @company.cases.not_deleted.where(
      stage: 'judgement_pending',
      status: 'in_court'
    ).where('judgement_expected_at IS NOT NULL AND judgement_expected_at <= ?', 30.days.from_now).order(:judgement_expected_at)
    
    cases.map do |case_record|
      days_left = ((case_record.judgement_expected_at - Time.current) / 1.day).ceil
      urgency = if days_left <= 3
                  :critical
                elsif days_left <= 7
                  :warning
                else
                  :normal
                end
      
      {
        item: case_record,
        days_left: days_left,
        urgency: urgency,
        link: case_path(case_record)
      }
    end
  end
  
  # 待归档的已结案件
  def pending_archives_data
    cases = @company.cases.not_deleted.where(status: 'closed').where(archived_at: nil).order(closed_at: :desc)
    
    cases.map do |case_record|
      days_since_closed = ((Time.current - case_record.closed_at) / 1.day).ceil
      urgency = if days_since_closed > 30
                  :critical
                elsif days_since_closed > 14
                  :warning
                else
                  :normal
                end
      
      {
        item: case_record,
        days_since_closed: days_since_closed,
        urgency: urgency,
        link: case_path(case_record)
      }
    end
  end
end
