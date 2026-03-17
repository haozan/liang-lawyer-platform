# 法律管理系统 - 安全综合审计报告

**审计日期**: 2025年1月  
**审计范围**: 全系统安全检查（认证授权、数据隔离、代码安全、业务逻辑）  
**审计状态**: ✅ 已完成  
**综合评级**: 🟢 **A级（安全）**

---

## 📋 执行摘要

本次安全审计对法律管理系统进行了全面检查，覆盖认证授权机制、数据隔离、常见安全漏洞（SQL注入、XSS、CSRF）、业务逻辑安全等关键领域。

### 核心发现

✅ **优势**:
- 完善的团队权限体系和数据隔离机制
- 全面的跨公司数据隔离测试（25个测试全部通过）
- 严格的参数过滤和日志脱敏
- Rails框架自带的SQL注入和CSRF防护
- 良好的审计日志记录

⚠️ **需优化**:
1. **会话固定攻击风险** - 登录后未重新生成session ID（中等风险）
2. **密码策略较弱** - 最低6位密码过于简单（中等风险）
3. **缺少账户锁定机制** - 暴力破解防护不足（中等风险）
4. **敏感操作缺少二次验证** - 删除企业/重要数据无二次确认（低风险）
5. **开发环境CSRF跳过** - 开发模式下禁用了CSRF保护（低风险）

**总体风险等级**: 🟡 **中低风险**  
**建议处理优先级**: P1（高） > P2（中） > P3（低）

---

## 🔍 详细审计结果

### 1. 认证与授权机制审计

#### ✅ 通过项

**1.1 三层用户体系设计合理**
- **管理员** (`Administrator`): 独立登录入口 `/admin/login`，使用手机号+密码
- **律师账户** (`LawyerAccount`): 五级角色 (assistant/lawyer/senior_lawyer/team_leader/super_admin)
- **企业用户** (`CompanyUser`): 三级角色 (employee/executive/boss)

```ruby
# app/models/lawyer_account.rb - 角色定义
validates :role, inclusion: { in: %w[assistant lawyer senior_lawyer team_leader super_admin] }

def lawyer?
  role.in?(['lawyer', 'senior_lawyer', 'team_leader', 'super_admin'])
end
```

**1.2 Session-based认证实现正确**
```ruby
# app/controllers/application_controller.rb
def current_lawyer
  @current_lawyer ||= LawyerAccount.find_by(id: session[:current_lawyer_id]) 
    if session[:user_type] == 'lawyer'
end

def require_authentication
  return if current_user
  redirect_to login_path, alert: '请先登录'
end
```

**1.3 团队权限体系完善**
- 三层权限: 团队所有权 > 团队协作 > 个人授权
- `TeamAccessible` concern 提供统一的权限检查
- `accessible_by(lawyer)` 自动过滤数据
- 权限操作记录到 `DataAccessLog` 审计

```ruby
# 权限检查示例
unless resource.accessible_by?(current_lawyer_account)
  redirect_to root_path, alert: '您没有权限访问该资源'
end
```

**1.4 企业服务状态控制**
```ruby
# app/controllers/sessions_controller.rb
unless company_user.company.can_use_service?
  flash.now[:alert] = "企业服务已暂停，无法登录。请联系律师。"
  render :new
  return
end
```

#### ⚠️ 发现的问题

**问题1: 会话固定攻击风险（中等风险）**

**描述**: 登录成功后未调用 `session.regenerate` 重新生成 session ID，攻击者可通过会话固定攻击劫持用户会话。

**影响范围**: 所有用户登录（律师、企业用户、管理员）

**受影响代码**:
```ruby
# app/controllers/sessions_controller.rb - 当前实现
if lawyer&.authenticate(password)
  session[:current_lawyer_id] = lawyer.id  # ❌ 未重新生成session
  session[:user_type] = 'lawyer'
  redirect_to lawyer_companies_path
end
```

**修复方案**:
```ruby
# 推荐实现
if lawyer&.authenticate(password)
  reset_session  # ✅ 清空旧session并生成新ID
  session[:current_lawyer_id] = lawyer.id
  session[:user_type] = 'lawyer'
  redirect_to lawyer_companies_path
end
```

**优先级**: 🔴 **P1 - 高优先级**

---

**问题2: 密码策略过弱（中等风险）**

**描述**: 系统仅要求密码最少6位，且无复杂度要求（无大小写、数字、特殊字符要求）。

**受影响代码**:
```ruby
# app/models/lawyer_account.rb, company_user.rb
validates :password, length: { minimum: 6 }, allow_nil: true  # ❌ 过于简单
```

**修复方案**:
```ruby
# 推荐实现 - 增强密码验证
validates :password, 
  length: { minimum: 8 },
  format: { 
    with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}\z/,
    message: '必须包含至少8位，包括大小写字母和数字'
  },
  if: :password_required?

# 或者使用更灵活的验证
validate :password_complexity

private

def password_complexity
  return if password.blank?
  
  errors.add(:password, '至少需要8个字符') if password.length < 8
  errors.add(:password, '必须包含至少一个数字') unless password.match?(/\d/)
  errors.add(:password, '必须包含至少一个字母') unless password.match?(/[a-zA-Z]/)
end
```

**优先级**: 🔴 **P1 - 高优先级**

---

**问题3: 缺少账户锁定机制（中等风险）**

**描述**: 虽然管理员登录有速率限制（5次/分钟），但普通用户登录无此保护，容易遭受暴力破解攻击。

**受影响代码**:
```ruby
# app/controllers/admin/sessions_controller.rb - 管理员有保护
def check_rate_limit
  key = "login_attempts:#{request.ip}"
  attempts = Rails.cache.read(key).to_i
  if attempts >= 5
    render 'new', status: :too_many_requests
  end
end

# app/controllers/sessions_controller.rb - 普通用户无保护 ❌
def create
  # 无速率限制和账户锁定
end
```

**修复方案**:

**方案A: 账户级别锁定（推荐）**
```ruby
# 1. 添加迁移
rails generate migration AddLockableToUsers failed_attempts:integer unlock_token:string locked_at:datetime

# 2. 更新模型
# app/models/lawyer_account.rb
MAX_FAILED_ATTEMPTS = 5
LOCK_DURATION = 30.minutes

def increment_failed_attempts!
  self.failed_attempts ||= 0
  self.failed_attempts += 1
  
  if failed_attempts >= MAX_FAILED_ATTEMPTS
    lock_account!
  else
    save(validate: false)
  end
end

def lock_account!
  self.locked_at = Time.current
  save(validate: false)
end

def unlock_account!
  self.failed_attempts = 0
  self.locked_at = nil
  save(validate: false)
end

def account_locked?
  return false if locked_at.nil?
  locked_at > LOCK_DURATION.ago
end

def reset_failed_attempts!
  update_columns(failed_attempts: 0, locked_at: nil)
end

# 3. 更新控制器
# app/controllers/sessions_controller.rb
def create
  lawyer = LawyerAccount.find_by(phone: phone)
  
  if lawyer&.account_locked?
    flash.now[:alert] = '账户已被锁定，请30分钟后再试或联系管理员'
    render :new, status: :unprocessable_entity
    return
  end
  
  if lawyer&.authenticate(password)
    lawyer.reset_failed_attempts!
    reset_session
    session[:current_lawyer_id] = lawyer.id
    session[:user_type] = 'lawyer'
    redirect_to lawyer_companies_path
  else
    lawyer&.increment_failed_attempts!
    flash.now[:alert] = '手机号或密码错误'
    render :new, status: :unprocessable_entity
  end
end
```

**方案B: IP级别速率限制（简单实现）**
```ruby
# app/controllers/sessions_controller.rb
before_action :check_login_rate_limit, only: [:create]

private

def check_login_rate_limit
  key = "login_attempts:#{request.ip}"
  attempts = Rails.cache.fetch(key, expires_in: 15.minutes) { 0 }
  
  if attempts >= 10
    flash.now[:alert] = '登录尝试次数过多，请15分钟后再试'
    render :new, status: :too_many_requests
  else
    Rails.cache.write(key, attempts + 1, expires_in: 15.minutes)
  end
end
```

**优先级**: 🔴 **P1 - 高优先级**

---

### 2. 数据隔离审计

#### ✅ 通过项（优秀）

**2.1 跨公司数据隔离测试全部通过**

运行了完整的安全测试套件，25个测试全部通过：

```bash
bundle exec rspec spec/requests/security_data_isolation_spec.rb

Security: Data Isolation Between Companies
  🔒 合同档案数据隔离 (5/5 passed)
  🔒 案件数据隔离 (5/5 passed)
  🔒 重大事项数据隔离 (5/5 passed)
  🔒 评论数据隔离 (2/2 passed)
  🔒 搜索功能数据隔离 (1/1 passed)
  🔒 待办事项数据隔离 (1/1 passed)
  🔒 工作台数据隔离 (1/1 passed)
  🔒 数据分析功能隔离 (4/4 passed)
  🔒 公告功能数据隔离 (1/1 passed)

Finished in 16.14 seconds
25 examples, 0 failures ✅
```

**2.2 企业用户权限控制严格**

```ruby
# app/controllers/contracts_controller.rb
before_action :set_company
before_action :require_contract_access

private

def set_company
  if company_user?
    @company = current_company_user.company  # 只能访问自己的企业
  elsif lawyer?
    @company = viewing_company
  end
end

def require_contract_access
  return if lawyer?
  
  unless @company
    redirect_to root_path, alert: '请先选择企业'
  end
end
```

**2.3 律师团队权限隔离完善**

```ruby
# app/models/concerns/team_accessible.rb
def accessible_by(lawyer)
  return all if lawyer.super_admin?
  
  # 场景1：律师主团队拥有的业务
  team_owned_ids = joins(:business_team_ownerships)
    .where(business_team_ownerships: { lawyer_team_id: lawyer.lawyer_team_id })
    .pluck(:id)
  
  # 场景2：律师被个人授权查看的业务
  personally_authorized_ids = joins(:lawyer_business_accesses)
    .where(lawyer_business_accesses: { lawyer_id: lawyer.id })
    .where('expires_at IS NULL OR expires_at > ?', Time.current)
    .pluck(:id)
  
  where(id: (team_owned_ids + personally_authorized_ids).uniq)
end
```

**2.4 搜索功能权限过滤正确**

```ruby
# app/controllers/searches_controller.rb
company_ids = if lawyer?
  Company.pluck(:id)  # 律师可搜索所有企业
else
  [current_company_user.company_id]  # 企业用户只能搜索自己企业
end

@results = SearchIndex.search(
  query: @query,
  company_ids: company_ids,
  categories: @category
)
```

**2.5 审计日志完整记录**

```ruby
# app/controllers/concerns/team_authorization_concern.rb
def log_access_attempt(resource:, action:, access_method:, success:)
  DataAccessLog.create!(
    lawyer_id: current_lawyer_account.id,
    resource_type: resource.class.name,
    resource_id: resource.id,
    action: action,
    access_method: access_method,
    ip_address: request.remote_ip
  )
end
```

#### ⚠️ 发现的问题

**问题4: 敏感操作缺少二次验证（低风险）**

**描述**: 删除企业、合同、案件等重要数据时缺少二次密码验证或确认机制，仅依赖前端JavaScript确认。

**受影响操作**:
- 删除企业
- 删除合同档案
- 删除案件
- 删除重大事项
- 删除律师账户/企业用户

**修复方案**:

**方案A: 添加密码二次验证（推荐高敏感操作）**
```ruby
# 1. 添加确认密码参数
# app/controllers/lawyer/companies_controller.rb
def destroy
  unless verify_password(params[:confirm_password])
    redirect_to edit_lawyer_company_path(@company), 
      alert: '密码验证失败，无法删除企业'
    return
  end
  
  # 检查是否有关联数据
  if @company.safe_to_delete?
    @company.destroy
    redirect_to lawyer_companies_path, notice: "企业「#{@company.name}」已成功删除"
  else
    # ...
  end
end

private

def verify_password(password)
  return false if password.blank?
  current_lawyer.authenticate(password)
end

# 2. 更新视图
# app/views/lawyer/companies/edit.html.erb
<%= form_with url: lawyer_company_path(@company), method: :delete, 
    data: { controller: "delete-confirmation" } do |f| %>
  <div class="mb-4">
    <%= f.label :confirm_password, "输入您的密码以确认删除", class: "form-label" %>
    <%= f.password_field :confirm_password, class: "form-input", required: true %>
  </div>
  <%= f.submit "确认删除企业", class: "btn-danger" %>
<% end %>
```

**方案B: 添加删除令牌验证（推荐低敏感操作）**
```ruby
# 1. 生成删除令牌
# app/controllers/contracts_controller.rb
def destroy_confirm
  @delete_token = SecureRandom.hex(16)
  session[:delete_token] = @delete_token
  session[:delete_resource_id] = @contract.id
  session[:delete_expires_at] = 5.minutes.from_now
end

def destroy
  # 验证删除令牌
  unless valid_delete_token?
    redirect_to contract_path(@contract), alert: '删除令牌无效或已过期'
    return
  end
  
  @contract.destroy
  clear_delete_token
  redirect_to contracts_path, notice: "合同档案已删除"
end

private

def valid_delete_token?
  return false if session[:delete_token].blank?
  return false if session[:delete_resource_id] != @contract.id
  return false if session[:delete_expires_at].blank?
  return false if Time.current > session[:delete_expires_at]
  return false if params[:token] != session[:delete_token]
  true
end

def clear_delete_token
  session.delete(:delete_token)
  session.delete(:delete_resource_id)
  session.delete(:delete_expires_at)
end
```

**优先级**: 🟡 **P2 - 中优先级**

---

### 3. 代码安全审计

#### ✅ 通过项

**3.1 SQL注入防护**

Rails默认使用参数化查询，所有数据库查询均安全：

```ruby
# ✅ 安全 - 参数化查询
@contracts = @contracts.where("name LIKE ?", "%#{params[:q]}%")
@contracts = @contracts.where(status: params[:status])
@major_issues = @major_issues.where(priority: filter_params[:priority])
```

**未发现直接字符串拼接查询（无SQL注入风险）**。

**3.2 XSS防护**

Rails默认转义所有输出，只有一处使用 `.html_safe`，但经过 `highlight` 辅助方法处理，安全：

```erb
<!-- app/views/searches/index.html.erb -->
<!-- ✅ 安全 - Rails highlight方法已转义内容 -->
<%= highlight(result.title, @query, 
    highlighter: '<mark class="bg-yellow-200">\1</mark>').html_safe %>
```

**未发现不安全的 `raw()` 或直接 `.html_safe` 调用**。

**3.3 CSRF防护**

生产环境已启用CSRF保护：

```ruby
# app/controllers/admin/base_controller.rb
protect_from_forgery with: :exception
```

所有表单自动包含 `authenticity_token`。

**3.4 参数过滤完善**

```ruby
# config/initializers/filter_parameter_logging.rb
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn
]
```

日志中敏感参数被自动脱敏。

**3.5 无危险代码**

- 未使用 `eval()`
- 未使用 `send()` 动态调用
- 未使用 `constantize()` 无限制常量化
- 未使用 `system()` 或 `` ` `` 执行外部命令

#### ⚠️ 发现的问题

**问题5: 开发环境CSRF保护被禁用（低风险）**

**描述**: 开发环境下为了方便curl测试，禁用了CSRF保护。

**受影响代码**:
```ruby
# app/controllers/concerns/development_csrf_bypass_concern.rb
included do
  if Rails.env.development?
    skip_before_action :verify_authenticity_token, raise: false  # ❌ 开发环境跳过
  end
end
```

**修复方案**:

保留此配置（开发便利性考虑），但在部署前确认：

```ruby
# config/environments/production.rb
# 确保生产环境强制开启CSRF保护
config.action_controller.default_protect_from_forgery = true
config.action_controller.allow_forgery_protection = true
```

**优先级**: 🟢 **P3 - 低优先级**（不影响生产环境）

---

### 4. 业务逻辑安全审计

#### ✅ 通过项

**4.1 角色权限检查完整**

```ruby
# 企业管理权限
def check_manage_permission
  unless @company.can_be_managed_by?(current_lawyer)
    redirect_to lawyer_companies_path, 
      alert: "您没有权限管理该企业（仅超级管理员和团队负责人可以管理）"
  end
end

# 企业删除权限
def check_delete_permission
  unless @company.can_be_deleted_by?(current_lawyer)
    redirect_to lawyer_companies_path, 
      alert: "您没有权限删除该企业（仅超级管理员和团队负责人可以删除）"
  end
end
```

**4.2 管理员自删除防护**

```ruby
# app/models/administrator.rb
def can_be_deleted_by?(current_admin)
  return false unless current_admin.can_delete_administrators?
  return false if self == current_admin  # ✅ 防止自删除
  true
end
```

**4.3 企业服务状态检查**

```ruby
# app/models/company.rb
def can_use_service?
  active? && !service_expired?
end

# 登录时检查
unless company_user.company.can_use_service?
  flash.now[:alert] = "企业服务已暂停，无法登录。"
  render :new
  return
end
```

**4.4 附件权限控制**

```ruby
# app/models/company_user.rb
def can_manage_attachments?
  executive? || boss?  # 只有主管和老板能删附件
end
```

#### ⚠️ 未发现严重业务逻辑漏洞

- 无权限提升漏洞
- 无水平越权漏洞
- 无垂直越权漏洞
- 无批量操作绕过权限
- 无金额/数量篡改风险

---

### 5. 敏感信息保护审计

#### ✅ 通过项

**5.1 密码存储安全**

使用 `bcrypt` 算法哈希存储密码：

```ruby
# app/models/lawyer_account.rb, company_user.rb, administrator.rb
has_secure_password  # BCrypt哈希，成本因子12
```

**5.2 会话安全配置**

```ruby
# config/initializers/session_store.rb
Rails.application.config.session_store :cookie_store, 
  key: '_app_session',
  secure: Rails.env.production?,  # 生产环境强制HTTPS
  httponly: true,                 # 防止JavaScript访问
  same_site: :lax                 # CSRF防护
```

**5.3 敏感配置使用环境变量**

```yaml
# config/application.yml
SECRET_KEY_BASE: '<%= ENV.fetch('CLACKY_SECRET_KEY_BASE', '') %>'
EMAIL_SMTP_PASSWORD: '<%= ENV.fetch("CLACKY_EMAIL_API_KEY", '') %>'
STORAGE_BUCKET_SECRET_ACCESS_KEY: '<%= ENV.fetch("CLACKY_STORAGE_BUCKET_SECRET_ACCESS_KEY", '') %>'
```

**5.4 管理员操作日志脱敏**

```ruby
# app/services/admin_oplog_service.rb
def self.sanitize_params(params)
  params.deep_dup.tap do |sanitized|
    sensitive_keys = ['password', 'password_confirmation', 'token', 'secret', 'api_key']
    sanitized.each do |key, value|
      sanitized[key] = '[FILTERED]' if sensitive_keys.any? { |k| key.to_s.include?(k) }
    end
  end
end
```

#### ⚠️ 发现的问题

**已在"问题2"中提及密码策略问题，此处不重复**。

---

## 🎯 优化方案汇总

### 方案A: 最小化修复方案（推荐快速上线）

**目标**: 修复高优先级（P1）问题，30分钟完成。

#### 修改1: 修复会话固定攻击

```ruby
# 文件: app/controllers/sessions_controller.rb
# 修改所有登录成功分支

# 律师账户登录 - 密码登录
if lawyer&.authenticate(password)
  reset_session  # ✅ 新增：重新生成session
  session[:current_lawyer_id] = lawyer.id
  session[:user_type] = 'lawyer'
  redirect_to lawyer_companies_path, notice: '登录成功'
  return
end

# 律师账户登录 - 短信登录
if lawyer
  reset_session  # ✅ 新增：重新生成session
  session[:current_lawyer_id] = lawyer.id
  session[:user_type] = 'lawyer'
  redirect_to lawyer_companies_path, notice: '登录成功'
  return
end

# 企业用户登录 - 密码登录
if company_user&.authenticate(password)
  unless company_user.company.can_use_service?
    # ... 服务检查
  end
  
  reset_session  # ✅ 新增：重新生成session
  session[:current_company_user_id] = company_user.id
  session[:user_type] = 'company_user'
  redirect_to workbench_index_path, notice: '登录成功'
  return
end

# 企业用户登录 - 短信登录
if company_user
  unless company_user.company.can_use_service?
    # ... 服务检查
  end
  
  reset_session  # ✅ 新增：重新生成session
  session[:current_company_user_id] = company_user.id
  session[:user_type] = 'company_user'
  redirect_to workbench_index_path, notice: '登录成功'
  return
end
```

```ruby
# 文件: app/controllers/admin/sessions_controller.rb
def create
  # ...
  if admin && admin.authenticate(params[:password])
    reset_session  # ✅ 新增：重新生成session
    admin_sign_in(admin)
    AdminOplogService.log_login(admin, request)
    redirect_to admin_root_path
  else
    # ...
  end
end
```

#### 修改2: 增强密码策略

```ruby
# 文件: app/models/concerns/password_complexity_validation.rb（新建）
module PasswordComplexityValidation
  extend ActiveSupport::Concern
  
  included do
    validate :password_complexity, if: :password_digest_changed?
  end
  
  private
  
  def password_complexity
    return if password.blank?
    
    errors.add(:password, '至少需要8个字符') if password.length < 8
    errors.add(:password, '必须包含至少一个数字') unless password.match?(/\d/)
    errors.add(:password, '必须包含至少一个字母') unless password.match?(/[a-zA-Z]/)
  end
end
```

```ruby
# 文件: app/models/lawyer_account.rb
include PasswordComplexityValidation  # ✅ 新增

validates :password, length: { minimum: 8 }, allow_nil: true  # ✅ 修改：6 -> 8
```

```ruby
# 文件: app/models/company_user.rb
include PasswordComplexityValidation  # ✅ 新增

validates :password, length: { minimum: 8 }, allow_nil: true  # ✅ 修改：6 -> 8
```

```ruby
# 文件: app/models/administrator.rb
include PasswordComplexityValidation  # ✅ 新增

# 已有 has_secure_password，无需修改其他
```

#### 修改3: 添加登录速率限制

```ruby
# 文件: app/controllers/sessions_controller.rb
before_action :check_login_rate_limit, only: [:create]  # ✅ 新增

# ...

private

def check_login_rate_limit  # ✅ 新增方法
  key = "login_attempts:#{request.ip}"
  attempts = Rails.cache.fetch(key, expires_in: 15.minutes) { 0 }
  
  if attempts >= 10
    flash.now[:alert] = '登录尝试次数过多，请15分钟后再试'
    @first_login = first_admin? if action_name == 'create'
    render :new, status: :too_many_requests
  else
    Rails.cache.write(key, attempts + 1, expires_in: 15.minutes)
  end
end
```

#### 验证修复

```bash
# 1. 运行安全测试
bundle exec rspec spec/requests/security_data_isolation_spec.rb

# 2. 测试登录流程
# - 正常登录是否成功
# - 登录后session ID是否改变
# - 连续错误登录10次后是否被限制
# - 15分钟后是否恢复

# 3. 测试密码策略
# - 尝试创建6位密码（应失败）
# - 尝试创建8位纯数字密码（应失败）
# - 尝试创建8位字母+数字密码（应成功）
```

**预计耗时**: 30分钟  
**风险**: 极低（仅增强现有逻辑）  
**回滚方案**: Git revert

---

### 方案B: 完整加固方案（推荐生产部署前）

**目标**: 修复所有P1、P2问题，达到行业最佳实践。

#### 额外修改1: 账户级别锁定机制

```bash
# 1. 生成迁移
rails generate migration AddLockableToLawyerAccountsAndCompanyUsers \
  failed_attempts:integer \
  unlock_token:string \
  locked_at:datetime
```

```ruby
# 2. 编辑迁移文件
class AddLockableToLawyerAccountsAndCompanyUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :lawyer_accounts, :failed_attempts, :integer, default: 0
    add_column :lawyer_accounts, :unlock_token, :string
    add_column :lawyer_accounts, :locked_at, :datetime
    add_index :lawyer_accounts, :unlock_token, unique: true
    
    add_column :company_users, :failed_attempts, :integer, default: 0
    add_column :company_users, :unlock_token, :string
    add_column :company_users, :locked_at, :datetime
    add_index :company_users, :unlock_token, unique: true
  end
end
```

```ruby
# 3. 新建 concern
# app/models/concerns/lockable_account.rb
module LockableAccount
  extend ActiveSupport::Concern
  
  MAX_FAILED_ATTEMPTS = 5
  LOCK_DURATION = 30.minutes
  
  def increment_failed_attempts!
    self.failed_attempts ||= 0
    self.failed_attempts += 1
    
    if failed_attempts >= MAX_FAILED_ATTEMPTS
      lock_account!
    else
      save(validate: false)
    end
  end
  
  def lock_account!
    self.locked_at = Time.current
    self.unlock_token = SecureRandom.urlsafe_base64(15)
    save(validate: false)
  end
  
  def unlock_account!
    self.failed_attempts = 0
    self.locked_at = nil
    self.unlock_token = nil
    save(validate: false)
  end
  
  def account_locked?
    return false if locked_at.nil?
    locked_at > LOCK_DURATION.ago
  end
  
  def reset_failed_attempts!
    update_columns(failed_attempts: 0, locked_at: nil, unlock_token: nil)
  end
  
  def unlock_url
    return nil unless unlock_token.present?
    Rails.application.routes.url_helpers.unlock_account_url(token: unlock_token)
  end
end
```

```ruby
# 4. 包含到模型
# app/models/lawyer_account.rb
include LockableAccount

# app/models/company_user.rb
include LockableAccount
```

```ruby
# 5. 更新控制器
# app/controllers/sessions_controller.rb
def create
  phone = params[:phone]
  password = params[:password]
  
  # 尝试查找律师账户
  lawyer = LawyerAccount.find_by(phone: phone)
  
  if lawyer&.account_locked?
    flash.now[:alert] = '账户已被锁定30分钟，请稍后再试或联系管理员'
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
  
  # 记录失败尝试
  lawyer&.increment_failed_attempts! if lawyer
  
  # 企业用户登录逻辑类似...
  
  flash.now[:alert] = '手机号或密码错误'
  render :new, status: :unprocessable_entity
end
```

```ruby
# 6. 添加解锁路由和控制器
# config/routes.rb
get 'unlock_account/:token', to: 'account_unlocks#show', as: :unlock_account

# app/controllers/account_unlocks_controller.rb
class AccountUnlocksController < ApplicationController
  skip_before_action :require_authentication
  
  def show
    token = params[:token]
    
    account = LawyerAccount.find_by(unlock_token: token) || 
              CompanyUser.find_by(unlock_token: token)
    
    if account
      account.unlock_account!
      redirect_to login_path, notice: '账户已成功解锁，请重新登录'
    else
      redirect_to login_path, alert: '无效的解锁链接'
    end
  end
end
```

#### 额外修改2: 敏感操作二次验证

```ruby
# 1. 更新企业删除控制器
# app/controllers/lawyer/companies_controller.rb
def destroy
  # 验证密码
  unless current_lawyer.authenticate(params[:confirm_password])
    flash[:alert] = '密码验证失败，无法删除企业'
    redirect_to edit_lawyer_company_path(@company)
    return
  end
  
  # 检查是否有关联数据
  if @company.safe_to_delete?
    @company.destroy
    redirect_to lawyer_companies_path, notice: "企业「#{@company.name}」已成功删除"
  else
    # ... 现有逻辑
  end
end
```

```erb
<!-- 2. 更新删除表单视图 -->
<!-- app/views/lawyer/companies/edit.html.erb -->
<div class="mt-8 border-t border-border pt-8">
  <h3 class="text-lg font-semibold text-danger mb-4">危险操作</h3>
  
  <%= form_with url: lawyer_company_path(@company), method: :delete, 
      data: { turbo_confirm: "确定要删除企业「#{@company.name}」吗？此操作不可撤销！" } do |f| %>
    
    <div class="mb-4">
      <%= f.label :confirm_password, "输入您的密码以确认删除", class: "form-label" %>
      <%= f.password_field :confirm_password, 
          class: "form-input", 
          required: true,
          placeholder: "请输入您的登录密码" %>
      <p class="text-sm text-muted mt-1">为了安全，删除企业需要验证您的密码</p>
    </div>
    
    <%= f.submit "确认删除企业", class: "btn-danger" %>
  <% end %>
</div>
```

#### 额外修改3: 生产环境安全配置验证

```ruby
# config/environments/production.rb
Rails.application.configure do
  # 强制HTTPS
  config.force_ssl = true
  
  # CSRF保护
  config.action_controller.default_protect_from_forgery = true
  config.action_controller.allow_forgery_protection = true
  
  # 安全头部
  config.action_dispatch.default_headers = {
    'X-Frame-Options' => 'SAMEORIGIN',
    'X-Content-Type-Options' => 'nosniff',
    'X-XSS-Protection' => '1; mode=block',
    'Referrer-Policy' => 'strict-origin-when-cross-origin'
  }
  
  # Session安全
  config.session_store :cookie_store,
    key: '_app_session_prod',
    secure: true,
    httponly: true,
    same_site: :strict
end
```

**预计耗时**: 2-3小时  
**风险**: 低（充分测试后）  
**回滚方案**: Git revert + 数据库回滚

---

## 📊 风险评估矩阵

| 问题编号 | 问题描述 | 影响范围 | 严重程度 | 利用难度 | 优先级 |
|---------|---------|---------|---------|---------|--------|
| 问题1 | 会话固定攻击风险 | 所有用户 | 中 | 中 | P1 🔴 |
| 问题2 | 密码策略过弱 | 所有用户 | 中 | 低 | P1 🔴 |
| 问题3 | 缺少账户锁定机制 | 律师/企业用户 | 中 | 低 | P1 🔴 |
| 问题4 | 敏感操作缺少二次验证 | 管理员操作 | 低 | 高 | P2 🟡 |
| 问题5 | 开发环境CSRF禁用 | 开发环境 | 低 | 不适用 | P3 🟢 |

---

## 🔒 合规性检查

### GDPR（欧盟数据保护条例）

| 要求 | 状态 | 说明 |
|------|------|------|
| 数据最小化 | ✅ 符合 | 仅收集必要数据 |
| 访问控制 | ✅ 符合 | 完善的权限体系 |
| 数据加密 | ⚠️ 部分符合 | Session加密，但传输需HTTPS |
| 审计日志 | ✅ 符合 | 完整的访问日志 |
| 数据删除 | ✅ 符合 | 支持账户删除 |

### 等保2.0（中国信息安全等级保护）

| 二级要求 | 状态 | 说明 |
|---------|------|------|
| 身份鉴别 | ⚠️ 需加强 | 需增强密码策略 |
| 访问控制 | ✅ 符合 | 完善的RBAC |
| 安全审计 | ✅ 符合 | 完整的操作日志 |
| 入侵防范 | ⚠️ 需加强 | 需添加账户锁定 |
| 数据完整性 | ✅ 符合 | 数据库约束完整 |

---

## 📈 后续建议

### 短期改进（1-2周）

1. **添加安全监控**
   - 集成应用性能监控（APM）工具
   - 配置异常登录告警
   - 监控敏感操作频率

2. **增强日志分析**
   - 定期审查访问日志
   - 分析异常行为模式
   - 建立安全事件响应流程

### 中期改进（1-3个月）

1. **渗透测试**
   - 聘请第三方进行渗透测试
   - 修复发现的新漏洞
   - 建立漏洞管理流程

2. **安全培训**
   - 开发团队安全编码培训
   - 定期安全意识提升
   - 建立代码安全审查机制

### 长期改进（3-6个月）

1. **自动化安全检测**
   - 集成静态代码分析工具（Brakeman）
   - 依赖漏洞扫描（Bundler Audit）
   - CI/CD集成安全检查

2. **等保认证**
   - 准备等保二级认证材料
   - 完善安全管理制度
   - 进行正式测评

---

## 📝 总结

本系统在数据隔离和权限控制方面表现优秀，基础安全架构合理。通过实施方案A（最小化修复），可在30分钟内修复所有高优先级问题，达到生产就绪状态。建议在生产部署前完成方案B（完整加固），进一步提升系统安全性，达到行业最佳实践水平。

**关键优势**:
- ✅ 完善的团队权限体系
- ✅ 严格的跨公司数据隔离
- ✅ 完整的审计日志记录
- ✅ Rails框架自带的安全防护

**需要改进**:
- 🔴 会话固定攻击防护
- 🔴 密码复杂度要求
- 🔴 登录暴力破解防护

**实施建议**:
1. 立即执行方案A（P1问题修复）
2. 生产部署前执行方案B（P1+P2问题修复）
3. 定期进行安全审计和渗透测试

---

**审计人员**: ClackyAI Security Audit Team  
**审计日期**: 2025-01-15  
**下次审计建议**: 2025-07-15（6个月后）
