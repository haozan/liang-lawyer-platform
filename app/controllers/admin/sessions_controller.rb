class Admin::SessionsController < Admin::BaseController
  skip_before_action :authenticate_admin!, only: [:new, :create]
  skip_before_action :check_first_login_password_hint, raise: false

  before_action do
    @full_render = true
  end

  before_action :check_rate_limit, only: [:create]

  def new
    @first_login = first_admin?
  end

  def create
    create_first_admin_or_reset_password!
    admin = Administrator.find_by(phone: params[:phone])
    if admin && admin.authenticate(params[:password])
      admin_sign_in(admin)
      AdminOplogService.log_login(admin, request)
      redirect_to admin_root_path
    else
      flash.now[:alert] = '手机号或密码错误'
      @first_login = first_admin?
      render 'new', status: :unprocessable_entity
    end
  end

  def destroy
    AdminOplogService.log_logout(current_admin, request) if current_admin
    admin_sign_out
    redirect_to admin_login_path
  end

  private

  def check_rate_limit
    key = "login_attempts:#{request.ip}"
    attempts = Rails.cache.read(key).to_i

    if attempts >= 5
      flash.now[:alert] = 'Too many login attempts. Please wait a moment and try again.'
      render 'new', status: :too_many_requests
    else
      Rails.cache.write(key, attempts + 1, expires_in: 1.minute)
    end
  end

  # 只在"系统还没有 admin"或"admin 账号从未修改过初始密码"时，才执行重置/创建
  # ⚠️ 关键修复：以前每次登录都会把密码重置为 'admin'，导致用户改完密码后又被冲掉
  def create_first_admin_or_reset_password!
    return unless first_admin?

    admin = Administrator.find_by(name: 'admin')
    if admin.nil?
      logger.info("System have no admins, create the first one")
      admin = Administrator.new(name: 'admin', phone: '10000000000', password: 'admin', role: 'super_admin')
      admin.save!(validate: false)
      return
    end

    # 只有当 admin 的密码 digest 为空，或者密码仍然是初始 'admin' 时，才重置
    # 这样用户修改过密码后，即使 first_login 字段异常也不会被冲掉
    needs_reset = admin.password_digest.blank? ||
                  (begin
                     BCrypt::Password.new(admin.password_digest).is_password?('admin')
                   rescue BCrypt::Errors::InvalidHash
                     true
                   end)

    return unless needs_reset

    logger.info("Reset first admin password to default 'admin'")
    if admin.phone.blank?
      admin.update_columns(phone: '10000000000', password_digest: BCrypt::Password.create('admin'))
    else
      admin.update!(password: 'admin', password_confirmation: 'admin')
    end
  end

  # first_login = true 表示该 admin 账号还从未被修改过
  # 一旦用户修改了密码，first_login 会被置为 false，此方法返回 false
  def first_admin?
    return true if Administrator.count.zero?
    Administrator.exists?(name: 'admin', first_login: true)
  end
end
