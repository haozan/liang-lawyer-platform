class Lawyer::CompanyTeamAccessesController < ApplicationController
  before_action :require_lawyer
  before_action :set_company
  before_action :require_team_leader_or_admin
  before_action :set_company_team_access, only: [:destroy]
  
  # 为企业添加协作团队授权
  def create
    @company_team_access = @company.company_team_accesses.new(company_team_access_params)
    @company_team_access.authorized_by = current_lawyer
    @company_team_access.authorized_at = Time.current
    
    if @company_team_access.save
      redirect_to edit_lawyer_company_path(@company), notice: "已授权「#{@company_team_access.lawyer_team.name}」访问此企业"
    else
      redirect_to edit_lawyer_company_path(@company), alert: "授权失败：#{@company_team_access.errors.full_messages.join(', ')}"
    end
  end
  
  # 移除协作团队授权
  def destroy
    team_name = @company_team_access.lawyer_team.name
    @company_team_access.destroy
    
    redirect_to edit_lawyer_company_path(@company), notice: "已撤销「#{team_name}」的访问权限"
  end
  
  private
  
  def set_company
    @company = Company.find(params[:company_id])
    
    # 检查当前律师是否有权限管理此企业
    unless @company.accessible_by_lawyer?(current_lawyer)
      redirect_to lawyer_companies_path, alert: "您无权管理此企业"
    end
  end
  
  def set_company_team_access
    @company_team_access = @company.company_team_accesses.find(params[:id])
  end
  
  def require_team_leader_or_admin
    # 只有企业主责团队的负责人或超级管理员可以管理团队授权
    unless current_lawyer.super_admin? || current_lawyer.team_leader_of?(@company.lawyer_team)
      redirect_to lawyer_companies_path, alert: "只有团队负责人可以管理团队授权"
    end
  end
  
  def company_team_access_params
    params.require(:company_team_access).permit(:lawyer_team_id, :access_level, :expires_at, :notes)
  end
end
