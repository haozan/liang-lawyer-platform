class ContractsController < ApplicationController
  before_action :set_company
  before_action :require_contract_access
  before_action :set_contract, only: [:show, :edit, :update, :destroy]

  def index
    @contracts = @company.contracts.ordered
    @contracts = @contracts.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?
  end

  def new
    @contract = @company.contracts.new
  end

  def create
    @contract = @company.contracts.new(contract_params)
    
    if @contract.save
      redirect_to contract_path(@contract), notice: "合同档案创建成功"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @comments = @contract.comments.ordered
    @comment = @contract.comments.new
  end

  def edit
  end

  def update
    if @contract.update(contract_params)
      redirect_to contract_path(@contract), notice: "合同档案已更新"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contract.destroy
    redirect_to contracts_path, notice: "合同档案已删除"
  end

  private

  def set_company
    @company = if lawyer?
      viewing_company || (redirect_to lawyer_companies_path, alert: "请先选择企业"; return)
    else
      current_company_user.company
    end
  end

  def require_contract_access
    return if lawyer?
    return if current_company_user&.role == 'contract'
    return if current_company_user&.role == 'boss'
    return if current_company_user&.employee?
    redirect_to root_path, alert: "无权访问"
  end

  def set_contract
    @contract = @company.contracts.find(params[:id])
  end

  def contract_params
    params.require(:contract).permit(:name, :signed_at, :end_at, :status, :file)
  end
end
