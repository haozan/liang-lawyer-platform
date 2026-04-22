class Admin::AccountsController < Admin::BaseController
  def edit
  end

  def update
    if current_admin.authenticate(params.require(:administrator)[:current_password])
      update_params = admin_params
      password_changed = update_params[:password].present?
      
      # Mark first login as false when password is changed
      update_params[:first_login] = false if password_changed

      if current_admin.update(update_params)
        # If password was changed, sign out and require re-login
        # Otherwise, update the session token to prevent logout
        if password_changed
          admin_sign_out
          redirect_to admin_login_path, notice: 'Password has been updated, please log in again'
        else
          # Update session token to reflect any changes
          session[:current_admin_token] = current_admin.password_digest
          redirect_to edit_admin_account_path, notice: 'Account has been updated successfully'
        end
      else
        render 'edit', status: :unprocessable_entity
      end
    else
      flash.now[:alert] = 'Old password is wrong, try again'
      render 'edit', status: :unprocessable_entity
    end
  end

  private

  def admin_params
    params.require(:administrator).permit(:name, :password, :password_confirmation)
  end
end
