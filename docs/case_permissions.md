# 案件管理模块权限设计

## 权限概述

案件管理模块实现了细粒度的权限控制，区分不同角色对案件信息和工作大事记的访问权限。

## 角色定义

1. **律师账户** (`LawyerAccount`)
   - 完全控制权限
   - 可以编辑案件所有信息
   - 可以添加/删除工作大事记
   - 可以添加律师意见

2. **企业主 - 老板账户** (`CompanyUser.boss?`)
   - 可以查阅本公司所有案件
   - 可以添加/删除工作大事记
   - 可以下载已归档案件的完整档案
   - **不能**编辑案件基本信息

3. **企业主 - 普通员工账户** (`CompanyUser.employee?`)
   - 可以查阅本公司所有案件
   - 可以添加/删除工作大事记
   - **不能**编辑案件基本信息
   - **不能**下载归档档案

## 权限矩阵

| 操作 | 律师 | 老板 | 员工 |
|------|------|------|------|
| 查看案件详情 | ✅ | ✅ | ✅ |
| 编辑案件基本信息 | ✅ | ❌ | ❌ |
| 添加工作大事记 | ✅ | ✅ | ✅ |
| 删除工作大事记 | ✅ | ✅ | ✅ |
| 查看附件 | ✅ | ✅ | ✅ |
| 下载附件 | ✅ | ✅ | ✅ |
| 下载归档档案 | ✅ | ✅ (仅已归档) | ❌ |
| 删除案件 | ✅ | ✅ | ⚠️ (需老板确认) |

## 实现细节

### 模型层权限方法 (`Case` model)

```ruby
# 是否已归档
def archived?
  archived_at.present?
end

# 企业用户是否可以编辑工作大事记
def can_company_user_edit_work_logs?(user)
  return false unless user.is_a?(CompanyUser)
  return false unless user.company_id == company_id
  user.employee? || user.boss?
end

# 企业用户是否可以编辑案件基本信息
def can_company_user_edit_case_info?(user)
  false  # 企业用户不能编辑案件基本信息
end

# 老板是否可以下载归档档案
def can_boss_download_archive?(user)
  return false unless user.is_a?(CompanyUser)
  return false unless user.company_id == company_id
  return false unless archived?
  user.boss?
end
```

### 控制器层权限检查

**工作大事记控制器** (`WorkLogsController`)
```ruby
before_action :require_work_log_permission

def require_work_log_permission
  return if current_lawyer
  return if current_company_user && @case.can_company_user_edit_work_logs?(current_company_user)
  
  redirect_to root_path, alert: '您没有权限操作工作大事记'
end
```

**案件控制器归档下载** (`CasesController#download_archive`)
```ruby
def download_archive
  unless current_company_user && @case.can_boss_download_archive?(current_company_user)
    redirect_to case_path(@case), alert: '您没有权限下载归档档案'
    return
  end
  # ... 生成ZIP文件
end
```

### 视图层权限控制

**工作大事记表单显示条件**
```erb
<% if current_lawyer || (current_company_user && @case.can_company_user_edit_work_logs?(current_company_user)) %>
  <!-- 显示添加工作记录表单 -->
<% end %>
```

**归档档案下载按钮显示条件**
```erb
<% if current_company_user && @case.can_boss_download_archive?(current_company_user) %>
  <%= link_to download_archive_case_path(@case), class: "btn-success" do %>
    下载归档档案
  <% end %>
<% end %>
```

## 归档档案内容

当老板账户下载已归档案件的完整档案时，ZIP文件包含：

1. **案件信息.txt** - 案件基本信息文本
2. **通用附件/** - 案件通用附件文件夹
3. **立案附件/** - 受理通知书等
4. **开庭附件/** - 传票等
5. **判决书附件/** - 判决书扫描件
6. **归档附件/** - 归档相关文件
7. **工作大事记/** - 所有工作记录及其附件
8. **律师意见/** - 已审核通过的律师意见及其附件

## 路由配置

```ruby
resources :cases do
  resources :work_logs, only: [:create, :destroy]
  member do
    get :download_archive  # GET /cases/:id/download_archive
  end
end
```

## 测试验证

### 功能测试结果

✅ 老板账户可以添加/删除工作大事记
✅ 员工账户可以添加/删除工作大事记
✅ 老板账户可以下载已归档案件的完整档案
✅ 员工账户无法下载归档档案（返回302重定向）
✅ 企业用户无法编辑案件基本信息（仅律师可以）
✅ 所有用户可以查看和下载案件附件
✅ 归档ZIP文件包含完整的案件材料

### 权限验证流程

1. **工作大事记权限**
   - 检查用户是否为律师或企业用户
   - 如果是企业用户，检查是否属于案件所属公司
   - 检查是否为员工或老板角色

2. **归档下载权限**
   - 检查用户是否为企业用户
   - 检查是否属于案件所属公司
   - 检查案件是否已归档（`archived_at` 不为空）
   - 检查是否为老板角色

## 安全考虑

1. **公司数据隔离** - 企业用户只能访问本公司的案件
2. **角色验证** - 所有权限检查都在模型层和控制器层双重验证
3. **视图层隐藏** - 根据权限隐藏不可访问的操作按钮
4. **归档状态检查** - 下载归档档案前必须检查案件是否已归档
5. **参数白名单** - 使用 Strong Parameters 防止未授权的字段修改

## 未来扩展

- 可以考虑添加更细粒度的权限控制（如特定员工的特殊权限）
- 可以添加归档下载日志记录
- 可以添加归档文件的在线预览功能
