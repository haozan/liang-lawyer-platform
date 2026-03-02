class MajorIssuesController < ApplicationController
  before_action :require_authentication
  before_action :set_company
  before_action :set_major_issue, only: [:show, :edit, :update, :destroy, :request_deletion, :confirm_deletion, :delete_directly]

  def index
    @major_issues = @company.major_issues.not_deleted.ordered.page(params[:page])
    
    # Stats for cards
    @all_count = @company.major_issues.not_deleted.count
    @pending_count = @company.major_issues.not_deleted.pending.count
    @discussing_count = @company.major_issues.not_deleted.discussing.count
    @resolved_count = @company.major_issues.not_deleted.resolved.count
    @urgent_count = @company.major_issues.not_deleted.where(priority: 'urgent').count
  end

  def show
    @comments = @major_issue.comments.approved.ordered
  end

  def new
    if lawyer?
      # 律师创建重大事项时,需要选择企业
      @companies = Company.ordered
      # 如果有 company_id 参数,使用指定的企业
      @selected_company = params[:company_id].present? ? Company.find(params[:company_id]) : @company
      @major_issue = MajorIssue.new
    else
      # 企业用户只能为自己的企业创建重大事项
      @major_issue = @company.major_issues.new
    end
    @lawyers = LawyerAccount.all
  end

  def edit
    @lawyers = LawyerAccount.all
  end

  def create
    if lawyer?
      # 律师创建重大事项时,必须指定 company_id
      company_id = major_issue_params[:company_id]
      if company_id.blank?
        redirect_to new_major_issue_path, alert: '请选择重大事项所属企业' and return
      end
      
      target_company = Company.find(company_id)
      @major_issue = target_company.major_issues.new(major_issue_params.except(:company_id))
    else
      # 企业用户只能为自己的企业创建重大事项
      @major_issue = @company.major_issues.new(major_issue_params)
    end
    
    if @major_issue.save
      redirect_to major_issue_path(@major_issue), notice: '重大事项已创建'
    else
      @lawyers = LawyerAccount.all
      if lawyer?
        @companies = Company.ordered
        @selected_company = @major_issue.company
      end
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @major_issue.update(major_issue_params)
      redirect_to major_issue_path(@major_issue), notice: '重大事项已更新'
    else
      @lawyers = LawyerAccount.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @major_issue.destroy
    redirect_to major_issues_path, notice: '重大事项已删除'
  end

  # Soft delete methods
  def request_deletion
    if current_user.role == 'employee'
      @major_issue.request_deletion_by_employee(current_user)
      redirect_to major_issue_path(@major_issue), notice: '删除请求已提交，等待老板确认'
    else
      redirect_to major_issue_path(@major_issue), alert: '只有员工可以请求删除'
    end
  end

  def confirm_deletion
    if current_user.role == 'boss'
      @major_issue.confirm_deletion_by_boss(current_user)
      redirect_to major_issues_path, notice: '删除请求已确认'
    else
      redirect_to major_issue_path(@major_issue), alert: '只有老板可以确认删除'
    end
  end

  def delete_directly
    if current_user.role == 'boss'
      @major_issue.delete_by_boss(current_user)
      redirect_to major_issues_path, notice: '重大事项已删除'
    else
      redirect_to major_issue_path(@major_issue), alert: '只有老板可以直接删除'
    end
  end

  private

  def require_authentication
    unless current_user || current_lawyer
      redirect_to login_path, alert: '请先登录'
    end
  end

  def set_company
    @company = if current_company_user
                 # 企业主只能访问自己的公司数据,防止客户信息泄露
                 current_company_user.company
               elsif current_lawyer
                 # 律师必须先选择企业
                 if session[:viewing_company_id]
                   Company.find(session[:viewing_company_id])
                 else
                   # 如果没有选择企业，重定向到律师工作台
                   redirect_to lawyer_companies_path, alert: '请先选择企业' and return
                 end
               end
    
    redirect_to root_path, alert: '未找到公司' unless @company
  end

  def set_major_issue
    @major_issue = @company.major_issues.find(params[:id])
  end

  def major_issue_params
    params.require(:major_issue).permit(
      :company_id,
      :title,
      :issue_type,
      :priority,
      :status,
      :description,
      :mentioned_lawyer_id,
      :resolved_at,
      :archived_at,
      attachments: []
    )
  end
end
