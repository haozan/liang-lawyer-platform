class Admin::LawyerTeamsController < Admin::BaseController
  before_action :set_lawyer_team, only: [:show, :edit, :update, :destroy]

  def index
    @lawyer_teams = LawyerTeam.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @lawyer_team = LawyerTeam.new
  end

  def create
    @lawyer_team = LawyerTeam.new(lawyer_team_params)

    if @lawyer_team.save
      redirect_to admin_lawyer_team_path(@lawyer_team), notice: '团队创建成功！'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @lawyer_team.update(lawyer_team_params)
      redirect_to admin_lawyer_team_path(@lawyer_team), notice: '团队更新成功！'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @lawyer_team.destroy
    redirect_to admin_lawyer_teams_path, notice: '团队已删除。'
  end

  private

  def set_lawyer_team
    @lawyer_team = LawyerTeam.find(params[:id])
  end

  def lawyer_team_params
    params.require(:lawyer_team).permit(:name, :code, :data_isolation_level, :status, :leader_id)
  end
end
