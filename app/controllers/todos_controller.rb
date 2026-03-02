class TodosController < ApplicationController
  before_action :set_company, if: :company_user?

  def index
    @filter = params[:filter] || 'all'
    
    # Get todo data based on user type
    if lawyer?
      # Lawyers use LawyerTodoService
      todo_service = LawyerTodoService.new
      todo_data = todo_service.call
    elsif company_user?
      # Company users use CompanyTodoService
      todo_service = CompanyTodoService.new(company: @company)
      todo_data = todo_service.call
    else
      redirect_to root_path, alert: '无权访问'
      return
    end
    
    @stats = todo_data[:stats]
    
    # Collect all items
    all_items = []
    all_items += todo_data[:urgent_items]
    all_items += todo_data[:pending_contracts]
    all_items += todo_data[:pending_cases]
    all_items += todo_data[:pending_major_issues]
    
    # Filter items based on filter parameter
    @todo_items = case @filter
                  when 'today'
                    all_items.select { |item| item[:record].created_at >= Time.current.beginning_of_day }
                  when 'pending'
                    all_items
                  when 'urgent'
                    todo_data[:urgent_items]
                  when 'reviewed'
                    # For reviewed items, show recent comments
                    if lawyer?
                      @recent_comments = Comment.where(author_role: ['lawyer', 'assistant'])
                                                .where('created_at >= ?', Time.current.beginning_of_week)
                                                .order(created_at: :desc)
                                                .limit(50)
                    else
                      # For company users, show comments related to their company
                      @recent_comments = Comment.where('created_at >= ?', Time.current.beginning_of_week)
                                                .where(
                                                  "(commentable_type = 'Contract' AND commentable_id IN (?)) OR 
                                                   (commentable_type = 'Case' AND commentable_id IN (?)) OR 
                                                   (commentable_type = 'MajorIssue' AND commentable_id IN (?))",
                                                  @company.contracts.pluck(:id),
                                                  @company.cases.not_deleted.pluck(:id),
                                                  @company.major_issues.not_deleted.pluck(:id)
                                                )
                                                .order(created_at: :desc)
                                                .limit(50)
                    end
                    []
                  else
                    all_items
                  end
    
    # Sort by priority and creation time
    @todo_items = @todo_items.sort_by { |item| [item[:priority] || 99, -item[:record].created_at.to_i] }
  end

  def mark_done
    # This method can be used to mark items as done in the future
    redirect_to todos_path, notice: '操作成功'
  end

  private

  def set_company
    @company = current_company_user.company
  end
end
