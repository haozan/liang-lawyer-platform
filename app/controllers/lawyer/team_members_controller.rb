class Lawyer::TeamMembersController < ApplicationController
  before_action :require_lawyer
  before_action :set_team
  before_action :require_team_leader

  def new
    @lawyer_account = LawyerAccount.new
  end

  def create
    @lawyer_account = LawyerAccount.new(lawyer_account_params)
    @lawyer_account.lawyer_team_id = @team.id
    
    if @lawyer_account.save
      redirect_to lawyer_team_path, notice: "成功为#{@lawyer_account.name}创建账户并加入团队"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def lawyer_account_params
    params.require(:lawyer_account).permit(:name, :phone, :password, :password_confirmation, :role)
  end

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
      redirect_to lawyer_team_path, alert: '只有团队负责人可以创建团队成员账户'
    end
  end
end
