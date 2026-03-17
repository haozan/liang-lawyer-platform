class ProfilesController < ApplicationController
  before_action :require_company_user

  def edit
  end

  def update
    if current_company_user.authenticate(params.require(:company_user)[:current_password])
      update_params = company_user_profile_params
      
      if current_company_user.update(update_params)
        # 修改密码后强制重新登录
        session[:current_company_user_id] = nil
        session[:user_type] = nil
        redirect_to login_path, notice: '账户信息已更新，请重新登录'
      else
        render :edit, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = '当前密码错误，请重试'
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def company_user_profile_params
    params.require(:company_user).permit(:name, :phone, :password, :password_confirmation)
  end
end
