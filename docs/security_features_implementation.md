# 安全加固功能说明文档

## 实施日期
2025年1月

## 实施的功能

### 1. 账户锁定机制

#### 功能描述
系统自动检测和防止暴力破解攻击，在连续失败登录后自动锁定账户。

#### 技术实现
- **数据库字段**（已迁移）：
  - `failed_attempts` - 失败尝试次数（默认0）
  - `locked_at` - 账户锁定时间
  - `unlock_token` - 解锁令牌（用于生成解锁链接）

- **锁定规则**：
  - 连续5次密码错误后自动锁定
  - 锁定时长：30分钟
  - 锁定期间禁止登录
  
- **解锁方式**：
  1. 自动解锁：锁定30分钟后自动失效
  2. 手动解锁：通过解锁令牌访问解锁链接（`/unlock_account/:token`）

#### 应用范围
- ✅ 律师账户（LawyerAccount）
- ✅ 企业用户账户（CompanyUser）

#### 用户体验
- 锁定时显示剩余锁定时间（分钟）
- 成功登录后自动清零失败次数
- 友好的错误提示

#### 核心代码
```ruby
# app/models/concerns/lockable_account.rb
module LockableAccount
  MAX_FAILED_ATTEMPTS = 5
  LOCK_DURATION = 30.minutes
  
  def increment_failed_attempts!
    # 递增失败次数，达到阈值后锁定
  end
  
  def account_locked?
    # 检查账户是否在锁定期内
  end
end
```

---

### 2. 敏感操作密码确认

#### 功能描述
对删除企业、合同、案件等重要数据的操作增加二次密码验证，防止误操作和未授权操作。

#### 技术实现
- **验证流程**：
  1. 用户点击删除按钮
  2. 弹出确认框，要求输入当前用户密码
  3. 后端验证密码是否正确
  4. 验证通过才执行删除操作

- **后端验证**：
```ruby
# 企业删除
def destroy
  unless current_lawyer.authenticate(params[:confirm_password])
    flash[:alert] = '密码验证失败，无法删除企业'
    redirect_to edit_lawyer_company_path(@company)
    return
  end
  # 执行删除...
end
```

#### 应用范围
- ✅ 企业删除（`Lawyer::CompaniesController#destroy`）
- ✅ 合同删除（`ContractsController#destroy`）
- ✅ 案件删除（`CasesController#destroy`）

#### 用户界面
- 使用Dropdown组件实现弹窗式密码输入
- 实时显示关联数据统计（阻止删除有关联数据的记录）
- 安全警告提示

#### 核心代码
```erb
<!-- 删除企业密码确认UI -->
<div data-controller="dropdown">
  <button data-dropdown-target="trigger">删除企业</button>
  <div data-dropdown-target="menu">
    <%= form_with url: lawyer_company_path(@company), method: :delete do |f| %>
      <%= f.password_field :confirm_password, placeholder: "请输入您的登录密码" %>
      <%= f.submit "确认删除企业" %>
    <% end %>
  </div>
</div>
```

---

## 安全测试结果

### 数据隔离测试
运行 `bundle exec rspec spec/requests/security_data_isolation_spec.rb`

**结果**：✅ **25/25 测试全部通过**

测试覆盖：
- 🔒 合同档案数据隔离（5个测试）
- 🔒 案件数据隔离（5个测试）
- 🔒 重大事项数据隔离（5个测试）
- 🔒 评论数据隔离（2个测试）
- 🔒 搜索功能数据隔离（1个测试）
- 🔒 待办事项数据隔离（1个测试）
- 🔒 工作台数据隔离（1个测试）
- 🔒 数据分析功能隔离（4个测试）
- 🔒 公告功能数据隔离（1个测试）

---

## 使用指南

### 对于系统管理员

#### 查看锁定账户
```ruby
# Rails console
LawyerAccount.where.not(locked_at: nil)
CompanyUser.where.not(locked_at: nil)
```

#### 手动解锁账户
```ruby
# Rails console
user = LawyerAccount.find_by(phone: "13800138001")
user.unlock_account!
```

#### 调整锁定策略
编辑 `app/models/concerns/lockable_account.rb`：
```ruby
MAX_FAILED_ATTEMPTS = 5      # 修改失败次数阈值
LOCK_DURATION = 30.minutes   # 修改锁定时长
```

### 对于开发人员

#### 添加新的敏感操作保护
1. 在控制器的destroy方法开头添加密码验证：
```ruby
def destroy
  if lawyer?
    unless current_lawyer.authenticate(params[:confirm_password])
      flash[:alert] = '密码验证失败，无法删除'
      redirect_to resource_path(@resource)
      return
    end
  end
  # 执行删除...
end
```

2. 更新视图，添加密码确认表单（参考`app/views/lawyer/companies/edit.html.erb`）

#### 为新用户模型添加锁定机制
1. 添加迁移：
```ruby
rails generate migration AddLockableToNewModel failed_attempts:integer unlock_token:string locked_at:datetime
```

2. 在模型中包含concern：
```ruby
class NewModel < ApplicationRecord
  include LockableAccount
end
```

3. 在登录逻辑中集成锁定检查（参考`sessions_controller.rb`）

---

## 安全建议

### 短期（已完成）
- ✅ 账户锁定机制
- ✅ 敏感操作密码确认
- ✅ 数据隔离验证

### 中期（建议实施）
1. **增强密码策略**
   - 提高密码最低复杂度要求
   - 强制定期更换密码
   - 密码历史记录（防止重用）

2. **操作日志审计**
   - 记录所有失败的登录尝试
   - 记录所有删除操作
   - 定期审查异常行为

3. **二次认证（2FA）**
   - 高权限账户强制启用2FA
   - 手机验证码/TOTP应用

### 长期（建议实施）
1. **安全监控系统**
   - 实时异常登录告警
   - IP黑名单机制
   - 自动封禁可疑IP

2. **渗透测试**
   - 定期第三方安全测试
   - 漏洞赏金计划

3. **合规认证**
   - 等保二级认证
   - ISO 27001认证

---

## 回滚方案

如果需要回滚此次安全加固，执行以下步骤：

```bash
# 1. Git回滚代码
git revert <commit-hash>

# 2. 回滚数据库迁移
rails db:rollback STEP=1

# 3. 重启服务
bin/dev
```

**警告**：回滚会移除所有锁定保护和密码确认功能。

---

## 技术文件清单

### 新增文件
- `app/models/concerns/lockable_account.rb` - 账户锁定逻辑
- `app/controllers/account_unlocks_controller.rb` - 账户解锁控制器
- `db/migrate/xxx_add_lockable_to_lawyer_accounts_and_company_users.rb` - 数据库迁移

### 修改文件
- `app/controllers/sessions_controller.rb` - 登录控制器集成锁定检查
- `app/controllers/lawyer/companies_controller.rb` - 企业删除密码确认
- `app/controllers/contracts_controller.rb` - 合同删除密码确认
- `app/controllers/cases_controller.rb` - 案件删除密码确认
- `app/views/lawyer/companies/edit.html.erb` - 企业删除UI
- `app/models/lawyer_account.rb` - 引入锁定concern
- `app/models/company_user.rb` - 引入锁定concern
- `config/routes.rb` - 添加解锁路由

---

## 联系与支持

如有问题或建议，请联系技术团队。

**文档版本**: 1.0  
**最后更新**: 2025年1月
