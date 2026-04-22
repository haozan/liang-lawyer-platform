class Admin::AccountsController < Admin::BaseController
  def edit
  end

  def update
    if current_admin.authenticate(params.require(:administrator)[:current_password])
      password_changed = params[:administrator][:password].present?
      
      # Get permitted params
      update_params = admin_params
      
      # Mark first login as false when password is changed
      if password_changed
        # Directly update the attribute along with password
        current_admin.first_login = false
      end

      if current_admin.update(update_params)
        # If password was changed, sign out and require re-login
        # Otherwise, update the session token to prevent logout
        if password_changed
          admin_sign_out
          redirect_to admin_login_path, notice: 'Password has been updated successfully. Please log in with your new password.'
        else
          # Update session token to reflect any changes
          session[:current_admin_token] = current_admin.password_digest
          redirect_to edit_admin_account_path, notice: 'Account has been updated successfully'
        end
      else
        render 'edit', status: :unprocessable_entity
      end
    else
      flash.now[:alert] = 'Current password is incorrect. Please try again.'
      render 'edit', status: :unprocessable_entity
    end
  end

  private

  def admin_params
    params.require(:administrator).permit(:name, :password, :password_confirmation)
  end
end
