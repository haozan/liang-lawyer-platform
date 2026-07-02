class MajorIssuesController < ApplicationController
  include CompanyResolvable

  before_action :require_authentication
  before_action :set_company
  before_action :set_major_issue, only: [:show, :edit, :update, :destroy, :resolve]

  def index
    base_scope = if lawyer? && @company
      @company.major_issues.ordered
    elsif lawyer?
      MajorIssue.ordered
    elsif @company
      @company.major_issues.ordered
    else
      MajorIssue.none
    end

    base_scope = base_scope.where(status: params[:status]) if params[:status].present?

    @major_issues = base_scope.page(params[:page]).per(20)
    @stats = {
      total: base_scope.count,
      pending: base_scope.pending.count,
      resolved: base_scope.resolved.count
    }
  end

  def show
    @comments = @major_issue.comments.ordered
  end

  def new
    @major_issue = MajorIssue.new
    @companies = Company.ordered if lawyer? && @company.nil?
  end

  def create
    target_company = if lawyer? && @company
      @company
    elsif lawyer?
      Company.find_by(id: major_issue_params[:company_id])
    else
      @company
    end

    unless target_company
      redirect_to new_major_issue_path, alert: '请选择所属企业' and return
    end

    @major_issue = target_company.major_issues.new(major_issue_params.except(:company_id))
    @major_issue.status = 'pending'

    if @major_issue.save
      redirect_to major_issue_path(@major_issue), notice: '重大事项已创建'
    else
      @companies = Company.ordered if lawyer? && @company.nil?
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @major_issue.update(major_issue_params.except(:attachments))
      # 附件追加
      if params.dig(:major_issue, :attachments).present?
        params[:major_issue][:attachments].each do |file|
          @major_issue.attachments.attach(file) if file.present?
        end
      end
      redirect_to major_issue_path(@major_issue), notice: '已更新'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @major_issue.destroy
    redirect_to major_issues_path, notice: '已删除'
  end

  # 标记为已解决
  def resolve
    unless lawyer?
      redirect_to major_issue_path(@major_issue), alert: '只有律师可以标记已解决' and return
    end

    @major_issue.resolve!
    redirect_to major_issue_path(@major_issue), notice: '已标记为已解决'
  end

  private

  def require_authentication
    redirect_to login_path, alert: '请先登录' unless current_user || current_lawyer
  end

  def set_major_issue
    if current_lawyer
      @major_issue = MajorIssue.find(params[:id])
      @company = @major_issue.company
    elsif current_company_user
      # 🔒 企业用户只能访问自己公司的重大事项（数据隔离）
      @company = viewing_company
      @major_issue = @company.major_issues.find(params[:id])
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def major_issue_params
    params.require(:major_issue).permit(
      :company_id, :title, :description,
      attachments: []
    )
  end
end
