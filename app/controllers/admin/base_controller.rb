class Admin::BaseController < ActionController::Base
  layout 'admin'

  include FriendlyErrorHandlingConcern
  include DevelopmentCsrfBypassConcern
  include TurboCompatibleRenderConcern

  protect_from_forgery with: :exception
  before_action :authenticate_admin!
  helper_method :current_admin

  private

  def authenticate_admin!
    unless current_admin
      redirect_to admin_login_path
    end
  end

  def current_admin
    @_current_admin ||= session[:current_admin_id] && Administrator.find_by(id: session[:current_admin_id])
  end

  def admin_sign_in(admin)
    session[:current_admin_id] = admin.id
    session[:current_admin_token] = admin.password_digest
  end

  def admin_sign_out
    session[:current_admin_id] = nil
    session[:current_admin_token] = nil
    @_current_admin = nil
  end
end
