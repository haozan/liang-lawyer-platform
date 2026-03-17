class Lawyer::TeamsController < ApplicationController
  before_action :require_lawyer
  before_action :set_team
  before_action :require_team_leader, only: [:add_member, :remove_member]

  def show
    @team_members = @team.lawyer_accounts.order(created_at: :asc)
    @available_lawyers = LawyerAccount.where(lawyer_team_id: nil).order(:name)
    
    # 统计团队业务数据
    @contracts_count = Contract.joins(:business_team_ownerships)
      .where(business_team_ownerships: { lawyer_team_id: @team.id })
      .distinct.count
    
    @cases_count = Case.joins(:business_team_ownerships)
      .where(business_team_ownerships: { lawyer_team_id: @team.id })
      .distinct.count
    
    @major_issues_count = MajorIssue.joins(:business_team_ownerships)
      .where(business_team_ownerships: { lawyer_team_id: @team.id })
      .distinct.count
  end
  
  def add_member
    lawyer = LawyerAccount.find(params[:lawyer_id])
    
    if lawyer.lawyer_team_id.present?
      redirect_to lawyer_team_path, alert: "#{lawyer.name}已在其他团队中，请先移除"
      return
    end
    
    lawyer.update!(lawyer_team_id: @team.id)
    redirect_to lawyer_team_path, notice: "已成功将#{lawyer.name}添加到团队"
  end
  
  def remove_member
    lawyer = LawyerAccount.find(params[:lawyer_id])
    
    if lawyer.id == @team.leader_id
      redirect_to lawyer_team_path, alert: '不能移除团队负责人'
      return
    end
    
    if lawyer.lawyer_team_id != @team.id
      redirect_to lawyer_team_path, alert: "#{lawyer.name}不在本团队中"
      return
    end
    
    lawyer.update!(lawyer_team_id: nil)
    redirect_to lawyer_team_path, notice: "已将#{lawyer.name}移出团队"
  end

  private
  
  def require_lawyer
    unless lawyer?
      redirect_to root_path, alert: '此功能仅限律师访问'
    end
  end
  
  def set_team
    unless current_lawyer.lawyer_team_id.present?
      redirect_to root_path, alert: '您尚未加入任何团队，请联系管理员'
      return
    end
    
    @team = current_lawyer.lawyer_team
  end
  
  def require_team_leader
    unless current_lawyer.team_leader_of?(@team)
      redirect_to lawyer_team_path, alert: '只有团队负责人可以管理成员'
    end
  end
end
