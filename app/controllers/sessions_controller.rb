class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: [:new, :create]
  
  def new
    # Show login page
  end
  
  def create
    # Try to authenticate as lawyer first
    lawyer = LawyerAccount.find_by(email: params[:email])
    if lawyer&.authenticate(params[:password])
      session[:current_lawyer_id] = lawyer.id
      session[:user_type] = 'lawyer'
      redirect_to lawyer_companies_path, notice: '登录成功'
      return
    end
    
    # Try to authenticate as company user
    company_user = CompanyUser.find_by(email: params[:email])
    if company_user&.authenticate(params[:password])
      session[:current_company_user_id] = company_user.id
      session[:user_type] = 'company_user'
      
      # Redirect based on role
      case company_user.role
      when 'boss'
        redirect_to boss_root_path, notice: '登录成功'
      when 'hr'
        redirect_to employees_path, notice: '登录成功'
      when 'contract'
        redirect_to contracts_path, notice: '登录成功'
      else
        redirect_to root_path, notice: '登录成功'
      end
      return
    end
    
    # Authentication failed
    flash.now[:alert] = '邮箱或密码错误'
    render :new, status: :unprocessable_entity
  end
  
  def destroy
    session.delete(:current_lawyer_id)
    session.delete(:current_company_user_id)
    session.delete(:user_type)
    session.delete(:viewing_company_id)
    redirect_to root_path, notice: '已退出登录'
  end
end
