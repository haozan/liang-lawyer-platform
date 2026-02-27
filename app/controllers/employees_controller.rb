class EmployeesController < ApplicationController
  before_action :set_company
  before_action :require_hr_access
  before_action :set_employee, only: [:show, :edit, :update, :destroy, :export_pdf]

  def index
    @employees = @company.employees.ordered
    @employees = @employees.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?
  end

  def new
    @employee = @company.employees.new
  end

  def create
    @employee = @company.employees.new(employee_params)
    
    if @employee.save
      redirect_to employee_path(@employee), notice: "员工档案创建成功"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @comments = @employee.comments.ordered
    @comment = @employee.comments.new
  end

  def edit
  end

  def update
    if @employee.update(employee_params)
      redirect_to employee_path(@employee), notice: "员工档案已更新"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @employee.destroy
    redirect_to employees_path, notice: "员工档案已删除"
  end

  def export_pdf
    pdf = EmployeePdfGeneratorService.new(@employee).call
    send_data pdf.render,
      filename: "员工档案_#{@employee.name}_#{Date.today.strftime('%Y%m%d')}.pdf",
      type: 'application/pdf',
      disposition: 'attachment'
  end

  private

  def set_company
    @company = if lawyer?
      viewing_company || (redirect_to lawyer_companies_path, alert: "请先选择企业"; return)
    else
      current_company_user.company
    end
  end

  def require_hr_access
    return if lawyer?
    return if current_company_user&.role == 'hr'
    return if current_company_user&.role == 'boss'
    redirect_to root_path, alert: "无权访问"
  end

  def set_employee
    @employee = @company.employees.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(:name, :gender, :id_number, :position, :salary, 
      :hired_at, :probation_end_at, :social_insurance_at, :contract_signed_at, :contract_end_at)
  end
end
