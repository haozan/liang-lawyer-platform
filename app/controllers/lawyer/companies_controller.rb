class Lawyer::CompaniesController < ApplicationController
  before_action :require_lawyer
  before_action :set_company, only: [:edit, :update, :destroy, :enter]

  def index
    @companies = Company.ordered
    
    # 获取待办数据
    todo_service = LawyerTodoService.new
    todo_data = todo_service.call
    
    @stats = todo_data[:stats]
    @urgent_items = todo_data[:urgent_items]
    @pending_contracts = todo_data[:pending_contracts]
    @pending_employees = todo_data[:pending_employees]
    @pending_regulations = todo_data[:pending_regulations]
    @company_todos = todo_data[:company_todos]
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)
    
    if @company.save
      # Create default HR and Contract users for the company
      hr_user = @company.company_users.create!(
        name: "#{@company.name}人事",
        email: "hr@#{@company.name.parameterize}.com",
        password: SecureRandom.hex(8),
        role: 'hr'
      )
      
      contract_user = @company.company_users.create!(
        name: "#{@company.name}合同",
        email: "contract@#{@company.name.parameterize}.com",
        password: SecureRandom.hex(8),
        role: 'contract'
      )
      
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
      redirect_to employees_path, notice: "当前查看：#{@company.name}"
    end
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name)
  end
end
