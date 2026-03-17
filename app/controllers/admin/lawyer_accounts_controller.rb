class Admin::LawyerAccountsController < Admin::BaseController
  before_action :set_lawyer_account, only: [:show, :edit, :update, :destroy]

  def index
    @lawyer_accounts = LawyerAccount.ordered.page(params[:page]).per(20)
  end

  def show
  end

  def new
    @lawyer_account = LawyerAccount.new
  end

  def create
    @lawyer_account = LawyerAccount.new(lawyer_account_params)

    if @lawyer_account.save
      redirect_to admin_lawyer_accounts_path, notice: '律师账号创建成功'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # 如果没有提供密码，则不更新密码
    update_params = lawyer_account_params
    if update_params[:password].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end
    
    if @lawyer_account.update(update_params)
      redirect_to admin_lawyer_accounts_path, notice: '律师账号已更新'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @lawyer_account.destroy
    redirect_to admin_lawyer_accounts_path, notice: '律师账号已删除'
  end

  private

  def set_lawyer_account
    @lawyer_account = LawyerAccount.find(params[:id])
  end

  def lawyer_account_params
    params.require(:lawyer_account).permit(:name, :role, :phone, :password, :password_confirmation)
  end
end
