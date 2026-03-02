class Lawyer::CompanyAccountsController < ApplicationController
  before_action :require_lawyer

  def index
    @companies = Company.includes(:company_users).ordered
  end

  def create
    company = Company.find(params[:company_id])
    company_user = company.company_users.build(company_user_params)
    
    if company_user.save
      redirect_to lawyer_company_accounts_path, notice: "企业账号创建成功"
    else
      redirect_to lawyer_company_accounts_path, alert: company_user.errors.full_messages.join(", ")
    end
  end

  def update
    company_user = CompanyUser.find(params[:id])
    
    if company_user.update(company_user_params)
      redirect_to lawyer_company_accounts_path, notice: "账号密码已重置"
    else
      redirect_to lawyer_company_accounts_path, alert: company_user.errors.full_messages.join(", ")
    end
  end

  def destroy
    company_user = CompanyUser.find(params[:id])
    company_user.destroy
    redirect_to lawyer_company_accounts_path, notice: "企业账号已删除"
  end

  private

  def company_user_params
    params.require(:company_user).permit(:name, :phone, :password, :password_confirmation, :role)
  end
end
