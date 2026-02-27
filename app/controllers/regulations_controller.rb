class RegulationsController < ApplicationController
  before_action :set_company
  before_action :require_hr_access
  before_action :set_regulation, only: [:show, :edit, :update, :destroy]

  def index
    @regulations = @company.regulations.ordered
    @regulations = @regulations.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?
  end

  def new
    @regulation = @company.regulations.new
  end

  def create
    @regulation = @company.regulations.new(regulation_params)
    
    if @regulation.save
      redirect_to regulation_path(@regulation), notice: "规章制度创建成功"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @comments = @regulation.comments.ordered
    @comment = @regulation.comments.new
  end

  def edit
  end

  def update
    if @regulation.update(regulation_params)
      redirect_to regulation_path(@regulation), notice: "规章制度已更新"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @regulation.destroy
    redirect_to regulations_path, notice: "规章制度已删除"
  end

  private

  def set_company
    @company = if lawyer?
      viewing_company || (redirect_to lawyer_companies_path, alert: "请先选择企业"; return)
    else
      current_company_user.company
    end
  end

  def require_hr_access
    return if lawyer?
    return if current_company_user&.role == 'hr'
    return if current_company_user&.role == 'boss'
    redirect_to root_path, alert: "无权访问"
  end

  def set_regulation
    @regulation = @company.regulations.find(params[:id])
  end

  def regulation_params
    params.require(:regulation).permit(:name, :file)
  end
end
