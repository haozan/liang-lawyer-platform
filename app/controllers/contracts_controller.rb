class ContractsController < ApplicationController
  include CompanyResolvable

  before_action :require_authentication
  before_action :set_company
  before_action :set_contract, only: [:show, :edit, :update, :destroy, :mark_as_reviewed]

  def index
    base_scope = if lawyer? && @company
      @company.contracts.ordered
    elsif lawyer?
      Contract.ordered
    elsif @company
      @company.contracts.ordered
    else
      Contract.none
    end

    # 简单筛选
    base_scope = base_scope.where(status: params[:status]) if params[:status].present?
    base_scope = base_scope.pending_review if params[:pending_review] == '1'

    if params[:keyword].present?
      base_scope = base_scope.where(
        "name ILIKE :q OR counterparty_name ILIKE :q",
        q: "%#{params[:keyword]}%"
      )
    end

    @contracts = base_scope.page(params[:page]).per(20)

    # 简单统计
    @stats = {
      total: base_scope.count,
      active: base_scope.active.count,
      expiring_soon: base_scope.expiring_soon.count,
      pending_review: base_scope.pending_review.count
    }
  end

  def show
    @comments = @contract.comments.ordered
    @reconciliations = @contract.reconciliations.ordered
  end

  def new
    @contract = Contract.new
    @companies = Company.ordered if lawyer? && @company.nil?
  end

  def create
    target_company = if lawyer? && @company
      @company
    elsif lawyer?
      Company.find_by(id: contract_params[:company_id])
    else
      @company
    end

    unless target_company
      redirect_to new_contract_path, alert: '请选择所属企业' and return
    end

    @contract = target_company.contracts.new(contract_params.except(:company_id))

    if @contract.save
      redirect_to contract_path(@contract), notice: '合同创建成功'
    else
      @companies = Company.ordered if lawyer? && @company.nil?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @companies = Company.ordered if lawyer?
  end

  def update
    if @contract.update(contract_params.except(:supplement_files))
      # 补充材料追加
      if params.dig(:contract, :supplement_files).present?
        params[:contract][:supplement_files].each do |file|
          @contract.supplement_files.attach(file) if file.present?
        end
      end
      redirect_to contract_path(@contract), notice: '合同信息已更新'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contract.destroy
    redirect_to contracts_path, notice: '合同已删除'
  end

  # 律师标记已审查
  def mark_as_reviewed
    unless lawyer?
      redirect_to contract_path(@contract), alert: '只有律师可以审查合同' and return
    end

    @contract.update!(
      reviewed_by_lawyer: true,
      reviewed_at: Time.current,
      reviewed_by_lawyer_id: current_lawyer.id
    )
    redirect_to contract_path(@contract), notice: '合同已标记为已审查'
  end

  private

  def require_authentication
    redirect_to login_path, alert: '请先登录' unless current_user || current_lawyer
  end

  def set_contract
    if current_lawyer
      @contract = Contract.find(params[:id])
      @company = @contract.company
    elsif current_company_user
      # 🔒 企业用户只能访问自己公司的合同（数据隔离）
      @company = viewing_company
      @contract = @company.contracts.find(params[:id])
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def contract_params
    params.require(:contract).permit(
      :company_id, :name, :counterparty_name, :contract_type,
      :contract_amount, :signed_at, :end_at, :status, :summary,
      :assigned_lawyer_id,
      :file, supplement_files: []
    )
  end
end
