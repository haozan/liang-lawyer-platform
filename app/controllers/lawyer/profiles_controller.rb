class Lawyer::ProfilesController < ApplicationController
  before_action :require_lawyer

  def edit
  end

  def update
    if current_lawyer.authenticate(params.require(:lawyer_account)[:current_password])
      update_params = lawyer_profile_params
      
      if current_lawyer.update(update_params)
        # 修改密码后强制重新登录
        session[:current_lawyer_id] = nil
        session[:user_type] = nil
        session[:viewing_company_id] = nil
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

  def lawyer_profile_params
    params.require(:lawyer_account).permit(:name, :phone, :password, :password_confirmation)
  end
end
