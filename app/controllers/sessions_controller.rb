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
    
    # Try to authenticate as company user (using phone instead of email)
    company_user = CompanyUser.find_by(phone: params[:phone])
    if company_user&.authenticate(params[:password])
      # 检查企业服务状态
      unless company_user.company.can_use_service?
        if company_user.company.suspended?
          flash.now[:alert] = "企业服务已暂停，无法登录。请联系律师。"
        elsif company_user.company.service_expired?
          flash.now[:alert] = "企业服务已到期，无法登录。请联系律师续期。"
        else
          flash.now[:alert] = "企业服务异常，无法登录。请联系律师。"
        end
        render :new, status: :unprocessable_entity
        return
      end
      
      session[:current_company_user_id] = company_user.id
      session[:user_type] = 'company_user'
      
      # 企业账户登录后统一跳转到工作台
      redirect_to workbench_index_path, notice: '登录成功'
      return
    end
    
    # Authentication failed
    flash.now[:alert] = '邮箱/电话或密码错误'
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
