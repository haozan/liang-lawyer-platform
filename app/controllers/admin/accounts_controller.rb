class Admin::AccountsController < Admin::BaseController
  def edit
  end

  def update
    unless current_admin.authenticate(params.require(:administrator)[:current_password])
      flash.now[:alert] = '当前密码不正确，请重试。'
      return render 'edit', status: :unprocessable_entity
    end

    password_changed = params[:administrator][:password].present?
    update_params = admin_params

    # 如果没有修改密码，移除空的 password 字段，避免 has_secure_password 抛错
    if !password_changed
      update_params = update_params.except(:password, :password_confirmation)
    end

    if current_admin.update(update_params)
      # ⚠️ 关键修复：密码改完后，强制落库 first_login = false
      # 用 update_column 绕过 callbacks / dirty tracking，确保一定写入数据库
      if password_changed && current_admin.first_login?
        current_admin.update_column(:first_login, false)
      end

      if password_changed
        # 密码改过了，session token 与 db 不一致，必须重登
        admin_sign_out
        redirect_to admin_login_path, notice: '密码修改成功，请使用新密码重新登录。'
      else
        # 没改密码，同步 session token 避免被 base_controller 踢出
        session[:current_admin_token] = current_admin.password_digest
        redirect_to edit_admin_account_path, notice: '账户信息已更新。'
      end
    else
      render 'edit', status: :unprocessable_entity
    end
  end

  private

  def admin_params
    params.require(:administrator).permit(:name, :password, :password_confirmation)
  end
end
