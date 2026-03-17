class Lawyer::LawyerAccountsController < ApplicationController
  before_action :require_lawyer
  before_action :set_lawyer_account, only: [:edit, :update, :destroy]

  def index
    @lawyer_accounts = LawyerAccount.ordered
  end

  def new
    @lawyer_account = LawyerAccount.new
  end

  def create
    @lawyer_account = LawyerAccount.new(lawyer_account_params)
    
    if @lawyer_account.save
      redirect_to lawyer_lawyer_accounts_path, notice: "律师账号创建成功"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @lawyer_account.update(lawyer_account_params)
      redirect_to lawyer_lawyer_accounts_path, notice: "律师账号已更新"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @lawyer_account.destroy
    redirect_to lawyer_lawyer_accounts_path, notice: "律师账号已删除"
  end

  private

  def set_lawyer_account
    @lawyer_account = LawyerAccount.find(params[:id])
  end

  def lawyer_account_params
    params.require(:lawyer_account).permit(:name, :phone, :password, :password_confirmation, :role)
  end
end
