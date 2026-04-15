class Admin::CompanyUsersController < Admin::BaseController
  before_action :set_company_user, only: [:show, :edit, :update, :destroy, :toggle_status]

  def index
    @company_users = CompanyUser.ordered.page(params[:page]).per(20)
    @company_users = @company_users.where('name LIKE ? OR phone LIKE ?',
                                          "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
  end

  def show
    @memberships = @company_user.company_memberships.includes(:company).ordered
  end

  def new
    @company_user = CompanyUser.new
  end

  def create
    @company_user = CompanyUser.new(company_user_params)
    if @company_user.save
      redirect_to admin_company_user_path(@company_user), notice: '企业用户创建成功'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    update_params = company_user_params
    update_params = update_params.except(:password, :password_confirmation) if update_params[:password].blank?

    if @company_user.update(update_params)
      redirect_to admin_company_user_path(@company_user), notice: '用户信息已更新'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @company_user.destroy
    redirect_to admin_company_users_path, notice: '用户已删除'
  end

  def toggle_status
    # 简单的锁定/解锁
    if @company_user.locked_at.present?
      @company_user.update!(locked_at: nil, failed_attempts: 0)
      redirect_to admin_company_user_path(@company_user), notice: '账号已解锁'
    else
      @company_user.update!(locked_at: Time.current)
      redirect_to admin_company_user_path(@company_user), notice: '账号已锁定'
    end
  end

  private

  def set_company_user
    @company_user = CompanyUser.find(params[:id])
  end

  def company_user_params
    params.require(:company_user).permit(:name, :phone, :password, :password_confirmation)
  end
end
