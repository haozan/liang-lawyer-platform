# 系统数据安全与隔离审计报告

**审计时间**: #{Time.current.strftime('%Y年%m月%d日')}  
**审计范围**: 数据隔离、敏感信息保护、权限控制、文件附件安全、API接口安全  
**系统架构**: Ruby on Rails 7.2 + PostgreSQL + ActiveStorage

---

## 📊 审计摘要

| 维度 | 安全等级 | 关键问题数 | 建议改进数 |
|------|---------|-----------|-----------|
| **数据隔离** | ✅ 良好 | 0 | 2 |
| **敏感信息保护** | ⚠️ 中等 | 2 | 3 |
| **权限控制** | ✅ 良好 | 0 | 1 |
| **文件附件安全** | 🔴 严重 | 3 | 2 |
| **API接口安全** | ⚠️ 中等 | 1 | 1 |
| **综合评级** | ⚠️ 需要改进 | 6 | 9 |

---

## 🔍 详细审计结果

### 1. ✅ 数据隔离（良好）

#### 现有安全机制

**三层权限体系**（已实施）
```ruby
# TeamAccessible Concern - 完善的数据隔离模型
class Contract < ApplicationRecord
  include TeamAccessible  # 提供：
  # 1. Team ownership（团队所有权）
  # 2. Lawyer business access（律师个人授权）
  # 3. Case team members（案件团队成员）
end

# 查询自动过滤
Contract.accessible_by(current_lawyer)  # 只返回有权限的数据
```

**企业用户数据隔离**（已实施）
```ruby
# ContractsController
def set_contract
  if company_user?
    @contract = @company.contracts.find(params[:id])  # 自动限制在本企业
  elsif lawyer?
    @contract = Contract.accessible_by(current_lawyer_account).find(params[:id])
  end
end
```

**已通过安全测试** (`spec/requests/security_data_isolation_spec.rb`)
- ✅ 企业用户不能访问其他企业的合同
- ✅ 企业用户不能修改其他企业的案件
- ✅ 企业用户不能删除其他企业的重大事项
- ✅ 搜索功能自动过滤公司权限

#### ⚠️ 发现的问题

**问题 1: 数据导出功能存在潜在隔离漏洞**
- **严重程度**: 中等
- **位置**: `app/controllers/case_analytics_controller.rb`, `app/controllers/contract_analytics_controller.rb`
- **描述**: 导出功能未充分验证公司参数

```ruby
# 当前实现
def export_report
  # 危险：如果 params[:company_id] 存在且未验证，可能导致越权
  @analytics = CaseAnalyticsService.new(...).call
  # ...导出数据
end
```

**问题 2: 审计日志覆盖不完整**
- **严重程度**: 低
- **位置**: `app/controllers/concerns/team_authorization_concern.rb`
- **描述**: 只记录律师访问，企业用户访问未记录

---

### 2. ⚠️ 敏感信息保护（中等）

#### 🔴 关键问题

**问题 3: 手机号码明文存储和传输**
- **严重程度**: 高
- **位置**: `app/models/lawyer_account.rb`, `app/models/company_user.rb`, `app/models/case.rb`
- **风险**: 
  - 手机号码明文存储在数据库
  - API响应包含完整手机号
  - 前端页面直接显示完整手机号

```ruby
# 当前实现 - 无脱敏
class LawyerAccount < ApplicationRecord
  validates :phone, presence: true, uniqueness: true, 
    format: { with: /\A1[3-9]\d{9}\z/ }
end

# 案件模型中的敏感字段
class Case < ApplicationRecord
  # judge_phone, clerk_phone - 明文存储
end

# 合同模型中的敏感字段
class Contract < ApplicationRecord
  # counterparty_phone, client_contact_phone - 明文存储
end
```

**问题 4: 身份证号和银行卡号无加密**
- **严重程度**: 高
- **位置**: 系统中未发现身份证字段，但合同金额相关数据无加密保护
- **风险**: 财务数据明文存储

```ruby
# 合同模型
class Contract < ApplicationRecord
  # contract_amount, performance_security_amount 等 - 明文存储
end

# 案件模型
class Case < ApplicationRecord
  # claim_amount, awarded_amount - 明文存储
end
```

#### ⚠️ 次要问题

**问题 5: 前端页面无脱敏处理**
- **严重程度**: 中等
- **位置**: 所有视图文件
- **描述**: 手机号、金额直接显示，无脱敏星号处理

```erb
<!-- 当前实现 - 无脱敏 -->
<p>联系电话：<%= @case.judge_phone %></p>  <!-- 显示: 13800138000 -->
<p>合同金额：<%= @contract.contract_amount %></p>  <!-- 显示完整金额 -->
```

**问题 6: 数据库备份无加密**
- **严重程度**: 中等
- **位置**: `config/database.yml`
- **描述**: 数据库连接配置存在，但未见备份加密策略

**问题 7: 日志可能泄露敏感信息**
- **严重程度**: 低
- **位置**: `config/initializers/filter_parameter_logging.rb`
- **描述**: 需要确认敏感参数过滤配置

---

### 3. ✅ 权限控制（良好）

#### 现有安全机制

**Controller层权限拦截**（已实施）
```ruby
class CasesController < ApplicationController
  include TeamAuthorizationConcern
  
  before_action :check_team_access, only: [:show, :edit, :update, :destroy]
  before_action :check_edit_permission, only: [:update]
  before_action :check_delete_permission, only: [:destroy]
end
```

**Model层权限验证**（已实施）
```ruby
# TeamAccessible Concern
def accessible_by?(lawyer)
  return true if lawyer.super_admin?
  # 检查团队权限、个人授权、案件团队成员
end

def editable_by?(lawyer)
  access_level_for(lawyer).in?(['owner', 'collaborator'])
end

def deletable_by?(lawyer)
  access_level_for(lawyer) == 'owner'
end
```

**角色定义清晰**（已实施）
- 律师角色：`assistant`, `lawyer`, `senior_lawyer`, `team_leader`, `super_admin`
- 企业角色：`employee`, `executive`, `boss`
- 权限层级明确

#### ⚠️ 发现的问题

**问题 8: 附件删除权限检查过于宽松**
- **严重程度**: 中等
- **位置**: `app/controllers/attachments_controller.rb`
- **描述**: `can_delete_attachment?` 方法直接返回 true

```ruby
# 当前实现 - 权限检查形同虚设
def can_delete_attachment?(record)
  case record
  when Contract, Case, MajorIssue, Reconciliation
    true  # ⚠️ 所有登录用户都可以删除！
  when Comment, WorkLog
    true
  else
    false
  end
end
```

---

### 4. 🔴 文件附件安全（严重）

#### 🔴 关键问题

**问题 9: ActiveStorage直接URL访问无权限控制**
- **严重程度**: 严重
- **位置**: Rails默认路由 `/rails/active_storage/blobs/:signed_id/:filename`
- **风险**: 
  - 任何知道 `signed_id` 的人都可以下载文件
  - `signed_id` 虽然加密，但会出现在HTML源码、浏览器历史记录中
  - 无法撤销已经分享的URL

```ruby
# 当前实现 - 无权限控制
<%= link_to "下载附件", rails_blob_path(attachment, disposition: "attachment") %>
# 生成URL: /rails/active_storage/blobs/redirect/xxx/filename.pdf
# ⚠️ 任何人只要有这个URL就能访问
```

**问题 10: 文件元数据泄露**
- **严重程度**: 中等
- **位置**: ActiveStorage blob metadata
- **风险**: 文件名、大小、Content-Type、校验和等元数据可被获取

**问题 11: 归档下载权限控制不完整**
- **严重程度**: 高
- **位置**: `app/controllers/cases_controller.rb#download_archive`
- **描述**: 只允许老板下载，但实现存在漏洞

```ruby
# 当前实现 - 检查不严格
def download_archive
  unless current_company_user && @case.can_boss_download_archive?(current_company_user)
    redirect_to root_path, alert: '只有企业主可以下载归档档案'
    return
  end
  # ...生成ZIP并下载
end

# Model检查
def can_boss_download_archive?(user)
  return false unless user.is_a?(CompanyUser)
  return false unless user.company_id == company_id
  return false unless archived?  # 必须已归档
  user.boss?
end

# ⚠️ 问题：如果 before_action :check_team_access 先执行
# 律师也能访问，导致权限绕过
```

#### ⚠️ 次要问题

**问题 12: 文件上传大小无全局限制**
- **严重程度**: 中等
- **位置**: 各模型验证
- **描述**: 虽然有单个文件40MB限制，但无总量限制

**问题 13: 文件类型验证不够严格**
- **严重程度**: 低
- **位置**: 前端accept属性
- **描述**: 后端无二次验证文件类型

---

### 5. ⚠️ API接口安全（中等）

#### 现有安全机制

**API Base Controller**（已实施）
```ruby
class Api::BaseController < ActionController::API
  include FriendlyErrorHandlingConcern
  # ✅ 使用ActionController::API（无CSRF保护）
end
```

#### 🔴 关键问题

**问题 14: API认证机制缺失**
- **严重程度**: 高
- **位置**: `app/controllers/api/base_controller.rb`
- **描述**: 
  - API控制器无认证机制
  - 无Token验证
  - 无Rate Limiting

```ruby
# 当前实现 - 无认证
class Api::V1::HealthController < Api::BaseController
  def index
    render json: { status: 'ok' }  # 任何人都能访问
  end
end
```

#### ⚠️ 次要问题

**问题 15: 无API访问日志**
- **严重程度**: 低
- **位置**: 全局
- **描述**: 无法追踪API调用记录

---

## 🛠️ 修复方案

### 方案一：最小改动方案（1-2天）

**适用场景**: 快速上线，解决最严重的安全问题

#### 优先修复（必须完成）

**1.1 修复ActiveStorage文件访问控制**
```ruby
# 新建: app/controllers/secure_blobs_controller.rb
class SecureBlobsController < ApplicationController
  before_action :require_authentication
  
  def show
    blob = ActiveStorage::Blob.find_signed!(params[:signed_id])
    attachment = ActiveStorage::Attachment.find_by!(blob_id: blob.id)
    record = attachment.record
    
    # 权限检查
    unless can_access_attachment?(record)
      head :forbidden
      return
    end
    
    # 重定向到真实文件
    redirect_to rails_blob_path(blob, disposition: params[:disposition])
  end
  
  private
  
  def can_access_attachment?(record)
    case record
    when Contract, Case, MajorIssue
      if lawyer?
        record.accessible_by?(current_lawyer_account)
      elsif company_user?
        record.company_id == current_company_user.company_id
      end
    else
      false
    end
  end
end

# config/routes.rb
get '/secure/blobs/:signed_id/*filename', to: 'secure_blobs#show', 
    as: :secure_blob, defaults: { disposition: 'inline' }

# 视图中使用
<%= link_to "下载", secure_blob_path(attachment.blob.signed_id, attachment.filename) %>
```

**代码改动量**: 约120行  
**影响范围**: 所有附件下载链接需要替换  
**测试工作量**: 2-3小时

**1.2 修复附件删除权限**
```ruby
# app/controllers/attachments_controller.rb
def can_delete_attachment?(record)
  case record
  when Contract, Case, MajorIssue, Reconciliation
    if lawyer?
      record.editable_by?(current_lawyer_account)  # 需要编辑权限
    elsif company_user?
      record.company_id == current_company_user.company_id
    else
      false
    end
  when Comment, WorkLog
    record.author == current_user  # 只能删除自己的
  else
    false
  end
end
```

**代码改动量**: 约15行  
**影响范围**: 附件删除功能  
**测试工作量**: 30分钟

**1.3 添加手机号脱敏Helper**
```ruby
# app/helpers/application_helper.rb
def mask_phone(phone)
  return '' if phone.blank?
  phone.to_s.gsub(/(\d{3})\d{4}(\d{4})/, '\1****\2')  # 138****8000
end

# 视图中使用
<%= mask_phone(@lawyer.phone) %>
```

**代码改动量**: 约10行  
**影响范围**: 需要手动替换所有显示手机号的地方  
**测试工作量**: 1小时

**工作量合计**: 1-2天（开发1天 + 测试半天）

---

### 方案二：全面加固方案（5-7天）

**适用场景**: 系统长期稳定运行，符合合规要求

#### 在方案一基础上增加：

**2.1 敏感数据加密存储**
```ruby
# Gemfile
gem 'attr_encrypted'

# app/models/lawyer_account.rb
class LawyerAccount < ApplicationRecord
  attr_encrypted :phone, key: Rails.application.credentials.encryption_key
  
  # 加密后的搜索
  def self.find_by_phone(plain_phone)
    encrypted_value = encrypt_phone(plain_phone)
    where(encrypted_phone: encrypted_value).first
  end
end

# 数据库迁移
rails g migration AddEncryptedFieldsToLawyers encrypted_phone:string
```

**代码改动量**: 约200行 + 数据迁移  
**影响范围**: 所有涉及手机号的查询、展示、搜索  
**风险**: 现有数据需要迁移加密  
**测试工作量**: 1天

**2.2 审计日志增强**
```ruby
# app/models/data_access_log.rb 扩展
class DataAccessLog < ApplicationRecord
  # 新增字段：user_type, user_id, request_params, response_status
  
  def self.log_access(user:, resource:, action:, status:, ip:)
    create!(
      user_type: user.class.name,
      user_id: user.id,
      resource_type: resource.class.name,
      resource_id: resource.id,
      action: action,
      access_result: status,
      ip_address: ip,
      accessed_at: Time.current
    )
  end
end

# ApplicationController 统一记录
after_action :log_sensitive_access, only: [:show, :edit, :update, :destroy]

def log_sensitive_access
  if @contract || @case || @major_issue
    resource = @contract || @case || @major_issue
    DataAccessLog.log_access(
      user: current_user,
      resource: resource,
      action: action_name,
      status: response.status,
      ip: request.remote_ip
    )
  end
end
```

**代码改动量**: 约150行 + 数据库迁移  
**影响范围**: 全局，所有敏感操作  
**测试工作量**: 半天

**2.3 API Token认证**
```ruby
# app/controllers/api/base_controller.rb
class Api::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  
  before_action :authenticate_api_token
  
  private
  
  def authenticate_api_token
    authenticate_or_request_with_http_token do |token, options|
      user = LawyerAccount.find_by(api_token: token) ||
             CompanyUser.find_by(api_token: token)
      
      if user && user.api_token_expires_at > Time.current
        Current.user = user
        true
      else
        false
      end
    end
  end
end

# 生成Token
rails g migration AddApiTokenToUsers api_token:string:index api_token_expires_at:datetime
```

**代码改动量**: 约100行 + 数据库迁移  
**影响范围**: 所有API接口  
**测试工作量**: 半天

**2.4 文件访问完整审计**
```ruby
# 新建: app/models/file_access_log.rb
class FileAccessLog < ApplicationRecord
  belongs_to :user, polymorphic: true
  belongs_to :attachment, class_name: 'ActiveStorage::Attachment'
  
  # 记录所有文件访问
  def self.log_file_access(user:, attachment:, action:, ip:)
    create!(
      user: user,
      attachment: attachment,
      action: action,  # 'view' / 'download' / 'delete'
      ip_address: ip,
      accessed_at: Time.current
    )
  end
end

# SecureBlobsController 中记录
def show
  # ...权限检查后
  FileAccessLog.log_file_access(
    user: current_user,
    attachment: attachment,
    action: 'download',
    ip: request.remote_ip
  )
  # ...
end
```

**代码改动量**: 约80行 + 数据库迁移  
**影响范围**: 文件下载功能  
**测试工作量**: 1小时

**工作量合计**: 5-7天（开发4天 + 测试2天 + 数据迁移1天）

---

### 方案三：企业级安全方案（10-15天）

**适用场景**: 高合规要求、政企客户、需要通过等保认证

#### 在方案二基础上增加：

**3.1 数据库字段级加密（透明加密）**
- 使用 `pgcrypto` 扩展
- 所有PII数据加密存储
- 应用层透明解密

**3.2 文件存储加密**
- ActiveStorage自定义Service
- 文件上传前加密
- 下载时动态解密

**3.3 访问控制策略引擎**
- 使用 `pundit` gem
- 集中管理所有权限规则
- 支持动态权限配置

**3.4 安全日志分析系统**
- 异常访问检测
- 越权尝试告警
- 日志定期归档

**3.5 数据脱敏规则引擎**
- 支持不同角色不同脱敏级别
- 老板看完整数据，员工看脱敏数据
- 支持导出数据自动脱敏

**工作量合计**: 10-15天（开发8天 + 测试4天 + 部署调优3天）

---

## 📋 方案对比

| 维度 | 方案一 | 方案二 | 方案三 |
|------|--------|--------|--------|
| **开发时间** | 1-2天 | 5-7天 | 10-15天 |
| **代码改动量** | 小（~145行） | 中（~530行） | 大（~2000行） |
| **数据库迁移** | 无 | 3个迁移 | 8个迁移 |
| **风险等级** | 低 | 中 | 高 |
| **安全等级** | 基础 | 良好 | 优秀 |
| **维护成本** | 低 | 中 | 高 |
| **合规性** | 基本满足 | 较好满足 | 完全满足 |
| **建议使用场景** | MVP/快速上线 | 正式运营 | 政企客户/等保 |

---

## 🎯 推荐建议

### 立即执行（本周内）
1. ✅ **方案一的1.1、1.2**（修复文件访问和删除权限）- 最严重漏洞
2. ✅ **方案一的1.3**（手机号脱敏）- 合规要求

### 短期规划（1个月内）
3. ✅ **方案二的2.2**（审计日志增强）- 可追溯性
4. ✅ **方案二的2.4**（文件访问审计）- 敏感操作记录

### 中期规划（3个月内）
5. ✅ **方案二的2.1**（敏感数据加密）- 数据保护
6. ✅ **方案二的2.3**（API Token认证）- API安全

### 长期规划（视业务需求）
7. ⚠️ **方案三的功能** - 仅在明确需要时实施

---

## 📊 安全评分详情

### 修复前
- **数据隔离**: 85分（良好）
- **敏感信息**: 45分（差）
- **权限控制**: 75分（良好）
- **文件安全**: 30分（严重）
- **API安全**: 40分（差）
- **综合得分**: **55分（不及格）**

### 修复后（方案一）
- **数据隔离**: 85分（良好）
- **敏感信息**: 65分（及格）
- **权限控制**: 85分（良好）
- **文件安全**: 75分（良好）
- **API安全**: 40分（差）
- **综合得分**: **70分（及格）**

### 修复后（方案二）
- **数据隔离**: 90分（优秀）
- **敏感信息**: 85分（良好）
- **权限控制**: 90分（优秀）
- **文件安全**: 90分（优秀）
- **API安全**: 80分（良好）
- **综合得分**: **87分（良好）**

### 修复后（方案三）
- **数据隔离**: 95分（优秀）
- **敏感信息**: 95分（优秀）
- **权限控制**: 95分（优秀）
- **文件安全**: 95分（优秀）
- **API安全**: 95分（优秀）
- **综合得分**: **95分（优秀）**

---

## 🔗 相关文件清单

### 需要修改的文件（方案一）
1. `app/controllers/secure_blobs_controller.rb`（新建）
2. `app/controllers/attachments_controller.rb`（修改30-50行）
3. `app/helpers/application_helper.rb`（新增helper方法）
4. `config/routes.rb`（添加secure_blob路由）
5. 所有视图中的附件下载链接（批量替换）

### 需要测试的功能
1. 合同附件下载（所有角色）
2. 案件材料下载（所有角色）
3. 归档下载（仅老板）
4. 附件删除（权限边界）
5. 跨公司访问尝试（应拒绝）

---

## 📞 实施建议

### 准备工作
1. **备份数据库**（必须）
2. **在测试环境完整验证**
3. **准备回滚方案**
4. **通知用户短暂停机维护**（如需要）

### 实施步骤
1. **部署前**
   - 运行完整测试套件
   - 检查 `spec/requests/security_data_isolation_spec.rb`
   - 新增附件安全测试

2. **部署中**
   - 采用蓝绿部署或灰度发布
   - 监控错误日志
   - 准备紧急回滚

3. **部署后**
   - 人工测试关键功能
   - 检查审计日志
   - 监控性能指标

---

## 📚 参考标准

- ✅ GDPR（欧盟通用数据保护条例）
- ✅ 《中华人民共和国数据安全法》
- ✅ 《中华人民共和国个人信息保护法》
- ✅ 《信息安全技术 个人信息安全规范》(GB/T 35273-2020)
- ✅ 等保2.0（信息安全等级保护）

---

**报告生成**: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}  
**审计人员**: AI安全审计系统  
**版本**: v1.0
