class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: [:new, :create, :select_company, :enter_company, :design_demo]
  before_action :set_full_render, only: [:new, :create, :design_demo]

  def new
    # Show login page
  end

  def create
    login_type = params[:login_type]

    case login_type
    when 'lawyer'
      handle_lawyer_login
    when 'user'
      handle_user_login
    else
      flash.now[:alert] = '无效的登录类型'
      render :new, status: :unprocessable_entity
    end
  end

  # 企业用户登录后选择企业（属于多个企业时）
  def select_company
    @company_user = CompanyUser.find_by(id: session[:pending_company_user_id])
    redirect_to login_path, alert: '请先登录' unless @company_user
    @companies = @company_user.companies.active
  end

  # 企业用户确认选择企业
  def enter_company
    company_user = CompanyUser.find_by(id: session[:pending_company_user_id])
    redirect_to login_path, alert: '请先登录' and return unless company_user

    company = company_user.companies.find_by(id: params[:company_id])
    redirect_to select_company_path, alert: '无效的企业' and return unless company

    unless company.can_use_service?
      redirect_to select_company_path, alert: service_unavailable_message(company) and return
    end

    company_user.reset_failed_attempts!
    session.delete(:pending_company_user_id)
    reset_session
    session[:current_company_user_id] = company_user.id
    session[:viewing_company_id] = company.id
    session[:user_type] = 'company_user'
    redirect_to cases_path, notice: "已进入「#{company.name}」工作台"
  end

  def destroy
    session.delete(:current_lawyer_id)
    session.delete(:current_company_user_id)
    session.delete(:viewing_company_id)
    session.delete(:pending_company_user_id)
    session.delete(:user_type)
    redirect_to root_path, notice: '已退出登录'
  end

  def design_demo
    render 'design_demo', layout: 'application'
  end

  private

  def set_full_render
    @full_render = true
  end

  # ---- 律师登录 ----
  def handle_lawyer_login
    phone    = params[:phone]
    password = params[:password]

    lawyer = LawyerAccount.find_by(phone: phone)

    if lawyer&.account_locked?
      flash.now[:alert] = "账户已被锁定#{lawyer.remaining_lock_time_in_minutes}分钟，请稍后再试或联系管理员"
      render :new, status: :unprocessable_entity and return
    end

    if lawyer&.authenticate(password)
      lawyer.reset_failed_attempts!
      reset_session
      session[:current_lawyer_id] = lawyer.id
      session[:user_type] = 'lawyer'
      redirect_to lawyer_companies_path, notice: '登录成功' and return
    end

    lawyer&.increment_failed_attempts!
    flash.now[:alert] = '手机号或密码错误'
    render :new, status: :unprocessable_entity
  end

  # ---- 企业用户登录 ----
  def handle_user_login
    phone    = params[:phone]
    password = params[:password]

    company_user = CompanyUser.find_by(phone: phone)

    if company_user&.account_locked?
      flash.now[:alert] = "账户已被锁定#{company_user.remaining_lock_time_in_minutes}分钟，请稍后再试或联系管理员"
      render :new, status: :unprocessable_entity and return
    end

    if company_user&.authenticate(password)
      login_as_company_user(company_user) and return
    end

    company_user&.increment_failed_attempts!
    flash.now[:alert] = '手机号或密码错误'
    render :new, status: :unprocessable_entity
  end

  # ---- 企业用户登录处理（核心：支持多企业） ----
  def login_as_company_user(company_user)
    companies = company_user.companies.active

    if companies.empty?
      flash.now[:alert] = '您的账号尚未关联任何企业，请联系管理员'
      render :new, status: :unprocessable_entity
      return true
    end

    if companies.count == 1
      company = companies.first
      unless company.can_use_service?
        flash.now[:alert] = service_unavailable_message(company)
        render :new, status: :unprocessable_entity
        return true
      end
      company_user.reset_failed_attempts!
      reset_session
      session[:current_company_user_id] = company_user.id
      session[:viewing_company_id] = company.id
      session[:user_type] = 'company_user'
      redirect_to cases_path, notice: '登录成功'
    else
      # 多个企业：存临时 session，跳转选企业页面
      session[:pending_company_user_id] = company_user.id
      redirect_to select_company_path
    end

    true
  end

  def service_unavailable_message(company)
    if company.suspended?
      '企业服务已暂停，无法登录。请联系律师。'
    elsif company.service_expired?
      '企业服务已到期，无法登录。请联系律师续期。'
    else
      '企业服务异常，无法登录。请联系律师。'
    end
  end
end
