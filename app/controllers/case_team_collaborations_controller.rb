class CaseTeamCollaborationsController < ApplicationController
  include TeamAuthorizationConcern
  
  before_action :require_authentication
  before_action :set_case
  before_action :check_case_access
  before_action :check_collaboration_permission
  
  def create
    @team = LawyerTeam.find(collaboration_params[:lawyer_team_id])
    
    # Check if team already has access
    existing = @case.business_team_ownerships.find_by(lawyer_team_id: @team.id)
    if existing
      render turbo_stream: turbo_stream.update(
        "collaboration-form-error",
        partial: "case_team_collaborations/error",
        locals: { message: "该团队已拥有此案件的访问权限" }
      ), status: :unprocessable_entity
      return
    end
    
    # Grant team access
    @ownership = @case.grant_team_access!(
      team: @team,
      access_level: collaboration_params[:access_level],
      authorized_by: current_lawyer_account,
      expires_at: nil
    )
    
    render turbo_stream: [
      turbo_stream.append(
        "collaborating-teams-list",
        partial: "case_team_collaborations/team",
        locals: { ownership: @ownership, case_record: @case }
      ),
      turbo_stream.update(
        "collaboration-form",
        partial: "case_team_collaborations/form",
        locals: { case_record: @case }
      ),
      turbo_stream.update(
        "collaborating-teams-count",
        partial: "case_team_collaborations/count",
        locals: { case_record: @case }
      )
    ]
  end
  
  def destroy
    @ownership = @case.business_team_ownerships.find(params[:id])
    
    # Cannot remove primary team
    if @ownership.is_primary?
      redirect_to case_path(@case), alert: '无法移除主责团队'
      return
    end
    
    @ownership.destroy
    
    render turbo_stream: [
      turbo_stream.remove("collaboration-team-#{@ownership.id}"),
      turbo_stream.update(
        "collaborating-teams-count",
        partial: "case_team_collaborations/count",
        locals: { case_record: @case }
      )
    ]
  end
  
  private
  
  def set_case
    @case = Case.find(params[:case_id])
  end
  
  def check_collaboration_permission
    # Only lead lawyer, team leader, or super admin can manage team collaborations
    unless @case.is_lead_lawyer?(current_lawyer_account) || 
           current_lawyer_account&.team_leader? || 
           current_lawyer_account&.super_admin?
      redirect_to case_path(@case), alert: '只有主办律师或团队负责人可以管理协作团队'
    end
  end
  
  def check_case_access
    # Skip check for non-lawyer users (they have their own authorization logic)
    return true unless lawyer?
    
    # Check if current lawyer has access to the case
    unless @case.accessible_by?(current_lawyer_account)
      redirect_to root_path, alert: '您没有权限访问该案件'
      return false
    end
    true
  end
  
  def collaboration_params
    params.require(:collaboration).permit(:lawyer_team_id, :access_level)
  end
end
