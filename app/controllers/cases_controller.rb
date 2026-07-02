class CasesController < ApplicationController
  include CompanyResolvable

  before_action :require_authentication
  before_action :set_company
  before_action :set_case, only: [:show, :edit, :update, :destroy, :append_attachments]

  def index
    @filter_params = filter_params

    base_scope = if lawyer? && @company
      @company.cases.not_deleted
    elsif lawyer?
      Case.not_deleted
    elsif @company
      @company.cases.not_deleted
    else
      Case.none
    end

    @cases = base_scope.includes(:company, :case_team_members)
                       .apply_filters(@filter_params)
                       .page(params[:page]).per(20)

    @stats = calculate_stats(base_scope)
    @filter_options = build_filter_options
  end

  def show
    @comments = @case.comments.ordered
    @work_logs = @case.work_logs.ordered
  end

  def new
    @case = Case.new
    @companies = Company.ordered if lawyer? && @company.nil?
  end

  def create
    target_company = if lawyer? && @company
      @company
    elsif lawyer?
      Company.find_by(id: case_params[:company_id])
    else
      @company
    end

    unless target_company
      redirect_to new_case_path, alert: '请选择案件所属企业' and return
    end

    @case = target_company.cases.new(case_params.except(:company_id))

    if @case.save
      redirect_to case_path(@case), notice: '案件创建成功'
    else
      @companies = Company.ordered if lawyer? && @company.nil?
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @companies = Company.ordered if lawyer?
  end

  def update
    if @case.update(case_params.except(:attachments))
      # 附件追加而非替换
      if params.dig(:case, :attachments).present?
        params[:case][:attachments].each do |file|
          @case.attachments.attach(file) if file.present?
        end
      end
      redirect_to case_path(@case), notice: '案件信息已更新'
    else
      @companies = Company.ordered if lawyer?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @case.destroy
    redirect_to cases_path, notice: '案件已删除'
  end

  def append_attachments
    unless lawyer?
      redirect_to case_path(@case), alert: '只有律师可以追加案件材料' and return
    end

    if params.dig(:case, :attachments).present?
      params[:case][:attachments].each do |file|
        @case.attachments.attach(file) if file.present?
      end
      redirect_to case_path(@case), notice: '案件材料已添加'
    else
      redirect_to case_path(@case), alert: '请选择要上传的文件'
    end
  end

  private

  def require_authentication
    redirect_to login_path, alert: '请先登录' unless current_user || current_lawyer
  end

  def set_case
    if current_lawyer
      @case = Case.find(params[:id])
      @company = @case.company
    elsif current_company_user
      # 🔒 企业用户只能访问自己公司的案件（数据隔离）
      @company = viewing_company
      @case = @company.cases.find(params[:id])
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def case_params
    params.require(:case).permit(
      :company_id, :name, :case_number, :case_type, :court_name,
      :status, :stage, :priority, :summary,
      :filing_at, :hearing_at, :judgement_received_at,
      :appeal_deadline_date, :property_preservation_applied_at,
      :property_preservation_deadline,
      :our_party_role, :our_party_name, :counterparty_name,
      :judge_name, :judge_phone, :clerk_name, :clerk_phone,
      attachments: [],
      case_team_members_attributes: [:id, :lawyer_account_id, :role, :_destroy]
    )
  end

  def filter_params
    params.permit(
      :keyword, :company_id, :sort_by, :sort_direction,
      statuses: [], stages: [], case_types: [], priorities: []
    )
  end

  def calculate_stats(scope)
    {
      total: scope.count,
      active: scope.active.count,
      urgent_hearings: scope.upcoming_hearings(7).count,
      preservation_expiring: scope.preservation_expiring(40).count
    }
  end

  def build_filter_options
    {
      companies: Company.ordered.pluck(:name, :id),
      statuses: Case::STATUS_LABELS.to_a.map { |k, v| [v, k] },
      stages: Case::STAGES,
      priorities: Case::PRIORITIES.to_a.map { |k, v| [v, k] }
    }
  end
end
