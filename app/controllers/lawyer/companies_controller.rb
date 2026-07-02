class Lawyer::CompaniesController < ApplicationController
  before_action :require_lawyer
  before_action :set_company, only: [:edit, :update, :destroy, :enter]

  def index
    @companies = Company.accessible_by_lawyer(current_lawyer).ordered

    # 简单统计
    accessible_ids = @companies.pluck(:id)
    @stats = {
      companies: @companies.count,
      pending_cases: Case.where(company_id: accessible_ids).where(status: 'active').count,
      pending_issues: MajorIssue.where(company_id: accessible_ids).pending.count,
      active_contracts: Contract.where(company_id: accessible_ids).where(status: 'active').count
    }
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)
    if @company.save
      redirect_to lawyer_companies_path, notice: "企业「#{@company.name}」创建成功"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @company.update(company_params)
      redirect_to lawyer_companies_path, notice: "企业信息已更新"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @company.cases.any? || @company.contracts.any?
      redirect_to edit_lawyer_company_path(@company), alert: '该企业下有案件或合同，无法删除'
    else
      @company.destroy
      redirect_to lawyer_companies_path, notice: "企业已删除"
    end
  end

  # 进入某企业视角
  def enter
    session[:viewing_company_id] = @company.id
    redirect_to cases_path, notice: "当前查看：#{@company.name}"
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name, :service_expires_at)
  end
end
