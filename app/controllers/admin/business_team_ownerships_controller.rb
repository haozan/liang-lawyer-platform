class Admin::BusinessTeamOwnershipsController < Admin::BaseController
  before_action :set_business_team_ownership, only: [:show, :edit, :update, :destroy]

  def index
    @business_team_ownerships = BusinessTeamOwnership.includes(:lawyer_team, :company, :business, :authorized_by).page(params[:page]).per(20)
    
    # 过滤：根据业务类型
    if params[:business_type].present?
      @business_team_ownerships = @business_team_ownerships.where(business_type: params[:business_type])
    end
    
    # 过滤：根据团队
    if params[:lawyer_team_id].present?
      @business_team_ownerships = @business_team_ownerships.where(lawyer_team_id: params[:lawyer_team_id])
    end
    
    # 过滤：根据是否为主团队
    if params[:is_primary].present?
      @business_team_ownerships = @business_team_ownerships.where(is_primary: params[:is_primary] == 'true')
    end
    
    # 过滤：根据访问级别
    if params[:access_level].present?
      @business_team_ownerships = @business_team_ownerships.where(access_level: params[:access_level])
    end
    
    @business_team_ownerships = @business_team_ownerships.order(created_at: :desc)
  end

  def show
  end

  def new
    @business_team_ownership = BusinessTeamOwnership.new
  end

  def create
    @business_team_ownership = BusinessTeamOwnership.new(business_team_ownership_params)
    @business_team_ownership.authorized_at = Time.current if @business_team_ownership.authorized_at.nil?

    if @business_team_ownership.save
      redirect_to admin_business_team_ownership_path(@business_team_ownership), notice: '业务授权创建成功！'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @business_team_ownership.update(business_team_ownership_params)
      redirect_to admin_business_team_ownership_path(@business_team_ownership), notice: '业务授权更新成功！'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @business_team_ownership.destroy
    redirect_to admin_business_team_ownerships_path, notice: '业务授权已删除。'
  end

  private

  def set_business_team_ownership
    @business_team_ownership = BusinessTeamOwnership.find(params[:id])
  end

  def business_team_ownership_params
    params.require(:business_team_ownership).permit(:business_type, :is_primary, :access_level, :authorized_at, :expires_at, :business_id, :lawyer_team_id, :company_id, :authorized_by_id)
  end
end
