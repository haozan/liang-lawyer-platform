class CaseTeamMembersController < ApplicationController
  include TeamAuthorizationConcern
  
  before_action :require_authentication
  before_action :set_case
  before_action :check_case_team_access, only: [:create]
  before_action :set_case_team_member, only: [:destroy]
  before_action :check_team_access, only: [:destroy]
  before_action :check_edit_permission

  def create
    @case_team_member = @case.case_team_members.new(case_team_member_params)
    
    if @case_team_member.save
      render turbo_stream: [
        turbo_stream.append(
          "case-team-members-list",
          partial: "case_team_members/member",
          locals: { member: @case_team_member }
        ),
        turbo_stream.update(
          "case-team-size",
          partial: "case_team_members/team_size",
          locals: { case_record: @case }
        ),
        turbo_stream.update(
          "add-member-form",
          partial: "case_team_members/form",
          locals: { case_record: @case, case_team_member: @case.case_team_members.new }
        )
      ]
    else
      render turbo_stream: turbo_stream.update(
        "add-member-form",
        partial: "case_team_members/form",
        locals: { case_record: @case, case_team_member: @case_team_member }
      ), status: :unprocessable_entity
    end
  end

  def destroy
    @case_team_member.destroy
    
    render turbo_stream: [
      turbo_stream.remove("case-team-member-#{@case_team_member.id}"),
      turbo_stream.update(
        "case-team-size",
        partial: "case_team_members/team_size",
        locals: { case_record: @case }
      )
    ]
  end

  private

  def set_case
    @case = Case.find(params[:case_id])
  end

  def set_case_team_member
    @case_team_member = @case.case_team_members.find(params[:id])
  end

  def case_team_member_params
    params.require(:case_team_member).permit(:lawyer_account_id, :role)
  end

  def check_case_team_access
    # create动作检查@case的访问权限
    return true unless lawyer?
    
    unless @case
      redirect_to root_path, alert: '资源不存在'
      return false
    end
    
    unless @case.accessible_by?(current_lawyer_account)
      redirect_to root_path, alert: '您没有权限访问该资源，请联系团队负责人申请权限'
      return false
    end
    
    true
  end

  def check_edit_permission
    # 只有案件的主办律师或团队负责人可以管理团队成员
    unless @case.is_lead_lawyer?(current_lawyer_account) || current_lawyer_account&.admin? || current_lawyer_account&.super_admin?
      redirect_to case_path(@case), alert: '只有主办律师或团队负责人可以管理案件团队成员'
    end
  end
end
