class Lawyer::CompaniesController < ApplicationController
  before_action :require_lawyer
  before_action :set_company, only: [:edit, :update, :destroy, :enter, :suspend, :resume]
  before_action :check_manage_permission, only: [:edit, :update, :suspend, :resume]
  before_action :check_delete_permission, only: [:destroy]
  before_action :check_create_permission, only: [:new, :create]

  def index
    # 企业筛选功能 - 只显示当前律师团队可访问的企业
    @selected_company_id = params[:company_id]
    @companies = Company.accessible_by_lawyer(current_lawyer).ordered
    
    # 获取待办数据 - 使用UnifiedTodoService
    todo_service = UnifiedTodoService.new(company_id: @selected_company_id, user_type: :lawyer)
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
    
    # 获取公告数据（根据选中的企业过滤）
    announcement_company_ids = if @selected_company_id.present?
      [@selected_company_id.to_i]
    else
      @companies.pluck(:id)
    end
    
    announcement_service = AnnouncementService.new(
      user: current_lawyer,
      company_ids: announcement_company_ids
    )
    announcement_data = announcement_service.call
    @announcements = announcement_data[:combined_announcements]
    @grouped_announcements = announcement_data[:grouped_announcements]
    @announcement_stats = announcement_data[:stats]
    @announcement_scope = @selected_company_id.present? ? Company.find(@selected_company_id).name : "全部企业"
    
    # 计算每个企业的公告数量并按降序排序（用于企业导航栏）
    # 优化：批量查询公告数量，避免N+1问题
    announcement_service_full = AnnouncementService.new(
      user: current_lawyer,
      company_ids: @companies.pluck(:id)
    )
    all_announcements = announcement_service_full.call[:combined_announcements]
    
    # 按company_id分组计数
    announcement_counts_by_company = all_announcements
      .select { |a| a[:related].respond_to?(:company_id) }
      .group_by { |a| a[:related].company_id }
      .transform_values(&:count)
    
    @companies_with_announcement_count = @companies.map do |company|
      OpenStruct.new(
        id: company.id,
        name: company.name,
        announcement_count: announcement_counts_by_company[company.id] || 0,
        company: company
      )
    end.sort_by { |c| -c.announcement_count }
  end

  def new
    @company = Company.new
    @lawyer_teams = LawyerTeam.active.ordered
  end

  def create
    @company = Company.new(company_params)
    
    # 设置企业的归属团队
    if params[:company][:lawyer_team_id].present?
      @company.lawyer_team_id = params[:company][:lawyer_team_id]
    else
      # 默认使用当前律师的团队
      @company.lawyer_team_id = current_lawyer.lawyer_team_id
    end
    
    if @company.save
      redirect_to lawyer_company_accounts_path(new_company_id: @company.id), notice: "企业「#{@company.name}」创建成功，请为该企业添加用户账号"
    else
      @lawyer_teams = LawyerTeam.active.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @company.update(company_params)
      redirect_to edit_lawyer_company_path(@company), notice: "✅ 企业信息已成功更新"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # 验证当前律师的密码
    unless current_lawyer.authenticate(params[:confirm_password])
      flash[:alert] = '密码验证失败，无法删除企业'
      redirect_to edit_lawyer_company_path(@company)
      return
    end
    
    # 检查是否有关联数据
    if @company.safe_to_delete?
      @company.destroy
      redirect_to lawyer_companies_path, notice: "企业「#{@company.name}」已成功删除"
    else
      summary = @company.associated_data_summary
      error_parts = []
      error_parts << "#{summary[:contracts_count]} 个合同" if summary[:contracts_count] > 0
      error_parts << "#{summary[:cases_count]} 个案件" if summary[:cases_count] > 0
      error_parts << "#{summary[:major_issues_count]} 个重大事项" if summary[:major_issues_count] > 0
      error_parts << "#{summary[:company_users_count]} 个企业账户" if summary[:company_users_count] > 0
      
      redirect_to edit_lawyer_company_path(@company), 
        alert: "无法删除企业：该企业还有 #{error_parts.join('、')}。请先删除或转移这些数据后再试。"
    end
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
  
  def check_manage_permission
    unless @company.can_be_managed_by?(current_lawyer)
      redirect_to lawyer_companies_path, alert: "您没有权限管理该企业（仅超级管理员和团队负责人可以管理）"
    end
  end
  
  def check_delete_permission
    unless @company.can_be_deleted_by?(current_lawyer)
      redirect_to lawyer_companies_path, alert: "您没有权限删除该企业（仅超级管理员和团队负责人可以删除）"
    end
  end
  
  def check_create_permission
    # 注意：can_be_created_by? 是类方法，但我们在实例上定义了它，需要使用一个新实例来检查
    unless current_lawyer.super_admin? || current_lawyer.team_leader?
      redirect_to lawyer_companies_path, alert: "您没有权限创建企业（仅超级管理员和团队负责人可以创建）"
    end
  end

  def company_params
    params.require(:company).permit(:name, :service_expires_at, :lawyer_team_id)
  end
end
