class Lawyer::CompaniesController < ApplicationController
  before_action :require_lawyer
  before_action :set_company, only: [:edit, :update, :destroy, :enter, :suspend, :resume]

  def index
    # 企业筛选功能
    @selected_company_id = params[:company_id]
    @companies = Company.ordered
    
    # 获取待办数据
    todo_service = LawyerTodoService.new(company_id: @selected_company_id)
    todo_data = todo_service.call
    
    @stats = todo_data[:stats]
    @urgent_items = todo_data[:urgent_items]
    @pending_contracts = todo_data[:pending_contracts]
    @pending_cases = todo_data[:pending_cases]
    @pending_major_issues = todo_data[:pending_major_issues]
    @company_todos = todo_data[:company_todos]
    
    # 获取届满提醒数据
    expiry_service = LawyerExpiryService.new(company_id: @selected_company_id)
    expiry_data = expiry_service.call
    
    @expiring_contracts = expiry_data[:expiring_contracts]
    @upcoming_hearings = expiry_data[:upcoming_hearings]
    @pending_judgement_collections = expiry_data[:pending_judgement_collections]
    @pending_archives = expiry_data[:pending_archives]
    @expiring_companies = expiry_data[:expiring_companies]
    @expiry_total_count = expiry_data[:total_count]
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)
    
    if @company.save
      redirect_to lawyer_companies_path, notice: "企业创建成功"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @company.update(company_params)
      redirect_to lawyer_companies_path, notice: "企业信息已更新"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @company.destroy
    redirect_to lawyer_companies_path, notice: "企业已删除"
  end

  def enter
    session[:viewing_company_id] = @company.id
    
    # 如果有指定的跳转目标，则跳转到该页面
    if params[:redirect_to].present?
      redirect_to params[:redirect_to], notice: "当前查看：#{@company.name}"
    else
      redirect_to contracts_path, notice: "当前查看：#{@company.name}"
    end
  end
  
  def suspend
    if @company.suspend!(reason: params[:reason], suspended_by_lawyer: current_lawyer)
      redirect_to lawyer_companies_path, notice: "企业服务已暂停"
    else
      redirect_to lawyer_companies_path, alert: "操作失败：#{@company.errors.full_messages.join(', ')}"
    end
  end
  
  def resume
    service_expires_at = params[:service_expires_at].present? ? Date.parse(params[:service_expires_at]) : nil
    
    if @company.resume!(service_expires_at: service_expires_at)
      redirect_to lawyer_companies_path, notice: "企业服务已恢复"
    else
      redirect_to lawyer_companies_path, alert: "操作失败：#{@company.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name, :service_expires_at)
  end
end
