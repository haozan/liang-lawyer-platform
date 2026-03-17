class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: [:new, :create, :design_demo]
  
  def new
    # Show login page
  end
  
  def create
    login_type = params[:login_type] || 'password'

    if login_type == 'sms'
      # SMS code login
      phone = params[:phone]
      sms_code = params[:sms_code]
      
      stored_code = session[:sms_code]
      stored_phone = session[:sms_phone]
      stored_time = session[:sms_time]
      
      # Validate SMS code
      if stored_code.blank? || stored_phone != phone
        flash.now[:alert] = '验证码无效或已过期'
        render :new, status: :unprocessable_entity
        return
      end
      
      # Check if code expired (5 minutes)
      if stored_time && Time.now.to_i - stored_time.to_i > 300
        flash.now[:alert] = '验证码已过期，请重新获取'
        session.delete(:sms_code)
        session.delete(:sms_phone)
        session.delete(:sms_time)
        render :new, status: :unprocessable_entity
        return
      end
      
      if sms_code != stored_code
        flash.now[:alert] = '验证码错误'
        render :new, status: :unprocessable_entity
        return
      end
      
      # Clear used SMS code
      session.delete(:sms_code)
      session.delete(:sms_phone)
      session.delete(:sms_time)
      
      # Try to find user by phone
      lawyer = LawyerAccount.find_by(phone: phone)
      if lawyer
        # Check if account is locked
        if lawyer.account_locked?
          flash.now[:alert] = "账户已被锁定#{lawyer.remaining_lock_time_in_minutes}分钟，请稍后再试"
          render :new, status: :unprocessable_entity
          return
        end
        
        lawyer.reset_failed_attempts!
        reset_session
        session[:current_lawyer_id] = lawyer.id
        session[:user_type] = 'lawyer'
        redirect_to lawyer_companies_path, notice: '登录成功'
        return
      end
      
      company_user = CompanyUser.find_by(phone: phone)
      if company_user
        # Check if account is locked
        if company_user.account_locked?
          flash.now[:alert] = "账户已被锁定#{company_user.remaining_lock_time_in_minutes}分钟，请稍后再试"
          render :new, status: :unprocessable_entity
          return
        end
        
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
        
        company_user.reset_failed_attempts!
        reset_session
        session[:current_company_user_id] = company_user.id
        session[:user_type] = 'company_user'
        redirect_to workbench_index_path, notice: '登录成功'
        return
      end
      
      flash.now[:alert] = '手机号不存在'
      render :new, status: :unprocessable_entity
    else
      # Password login
      phone = params[:phone]
      password = params[:password]
      
      # Try to authenticate as lawyer first
      lawyer = LawyerAccount.find_by(phone: phone)
      
      # Check if lawyer account is locked
      if lawyer&.account_locked?
        flash.now[:alert] = "账户已被锁定#{lawyer.remaining_lock_time_in_minutes}分钟，请稍后再试或联系管理员"
        render :new, status: :unprocessable_entity
        return
      end
      
      if lawyer&.authenticate(password)
        lawyer.reset_failed_attempts!
        reset_session
        session[:current_lawyer_id] = lawyer.id
        session[:user_type] = 'lawyer'
        redirect_to lawyer_companies_path, notice: '登录成功'
        return
      end
      
      # Record failed attempt for lawyer
      lawyer&.increment_failed_attempts!
      
      # Try to authenticate as company user
      company_user = CompanyUser.find_by(phone: phone)
      
      # Check if company user account is locked
      if company_user&.account_locked?
        flash.now[:alert] = "账户已被锁定#{company_user.remaining_lock_time_in_minutes}分钟，请稍后再试或联系管理员"
        render :new, status: :unprocessable_entity
        return
      end
      
      if company_user&.authenticate(password)
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
        
        company_user.reset_failed_attempts!
        reset_session
        session[:current_company_user_id] = company_user.id
        session[:user_type] = 'company_user'
        
        # 企业账户登录后统一跳转到工作台
        redirect_to workbench_index_path, notice: '登录成功'
        return
      end
      
      # Record failed attempt for company user
      company_user&.increment_failed_attempts!
      
      # Authentication failed
      flash.now[:alert] = '手机号或密码错误'
      render :new, status: :unprocessable_entity
    end
  end
  
  def destroy
    session.delete(:current_lawyer_id)
    session.delete(:current_company_user_id)
    session.delete(:user_type)
    session.delete(:viewing_company_id)
    redirect_to root_path, notice: '已退出登录'
  end

  def design_demo
    render 'design_demo', layout: 'application'
  end
  
  # TODO: SMS verification code feature
  # To implement SMS login, integrate with SMS provider (Aliyun, Tencent Cloud, etc.)
  # and implement send_sms_code method using Turbo Stream architecture
  # def send_sms_code
  #   # 1. Validate phone number
  #   # 2. Generate verification code
  #   # 3. Send SMS via provider
  #   # 4. Store code in session
  #   # 5. Respond with Turbo Stream to update UI
  # end
end
