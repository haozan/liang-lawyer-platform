# 附件下载功能修复文档

## 🐛 问题描述

**报告时间**: 2026-03-15 09:37  
**严重级别**: 🔴 高 - 影响核心功能  
**影响范围**: 合同详情页和案件详情页的附件下载功能

### 用户反馈

用户在合同详情页和案件管理详情页点击"下载"按钮后，浏览器显示的是预览（inline）而不是下载（attachment），无法触发文件下载。

### 问题表现

- ✅ 预览按钮功能正常
- ❌ 下载按钮点击后文件在浏览器中预览而非下载
- ❌ 对于PDF等文件，用户无法保存到本地

---

## 🔍 根本原因分析

### 1. 路由配置分析

在 `config/routes.rb` 中存在两条附件访问路由:

```ruby
# Line 181 - 预览路由
get "/secure/blobs/:signed_id/*filename", 
  to: "secure_blobs#show", 
  as: :secure_blob, 
  defaults: { disposition: "inline" }

# Line 182 - 下载路由
get "/secure/blobs/:signed_id/*filename/download", 
  to: "secure_blobs#show", 
  as: :secure_blob_download, 
  defaults: { disposition: "attachment" }
```

### 2. Helper 方法问题

在 `app/helpers/application_helper.rb` 中的 `secure_blob_url_for` 方法存在逻辑错误:

**错误代码 (Before)**:
```ruby
def secure_blob_url_for(attachment, disposition: 'inline')
  if attachment.is_a?(ActiveStorage::Blob)
    blob = attachment
  else
    blob = attachment.blob
  end
  # ❌ 始终使用 secure_blob_path，忽略 disposition 参数
  secure_blob_path(blob.signed_id, attachment.filename, disposition: disposition)
end
```

**问题**:
- Helper 方法始终调用 `secure_blob_path`
- 虽然传递了 `disposition: 'attachment'` 参数
- 但 `secure_blob_path` 路由的默认值 `defaults: { disposition: "inline" }` 会覆盖传递的参数
- 导致所有附件访问都使用 `inline` 模式（预览）

### 3. 调用链分析

下载按钮的调用链:

```
smart_file_link (action_buttons: true)
  ↓
build_action_buttons_group
  ↓
secure_blob_url_for(attachment, disposition: 'attachment')  # ✅ 传递了正确参数
  ↓
secure_blob_path(blob.signed_id, filename, disposition: disposition)  # ❌ 但使用了错误的路由
  ↓
/secure/blobs/:signed_id/*filename (inline route)  # ❌ 结果: 预览而非下载
```

**应该使用**:
```
secure_blob_download_path(blob.signed_id, filename)  # ✅ 专用下载路由
  ↓
/secure/blobs/:signed_id/*filename/download  # ✅ 结果: 触发下载
```

---

## ✅ 修复方案

### 修改文件: `app/helpers/application_helper.rb`

**修改位置**: 第 59-72 行

**修复后代码**:
```ruby
# 生成安全文件访问路径(需要权限验证)
def secure_blob_url_for(attachment, disposition: 'inline')
  if attachment.is_a?(ActiveStorage::Blob)
    blob = attachment
  else
    blob = attachment.blob
  end
  
  # 根据 disposition 选择正确的路由
  if disposition.to_s == 'attachment'
    secure_blob_download_path(blob.signed_id, attachment.filename)
  else
    secure_blob_path(blob.signed_id, attachment.filename)
  end
end
```

### 核心改进

1. **条件路由选择**: 根据 `disposition` 参数选择对应的路由
   - `disposition: 'attachment'` → 使用 `secure_blob_download_path` (下载)
   - `disposition: 'inline'` → 使用 `secure_blob_path` (预览)

2. **利用现有路由**: 充分利用了 `config/routes.rb` 中已存在的两条路由
   - 无需修改路由配置
   - 无需修改 controller 逻辑
   - 仅需修正 helper 方法的路由选择逻辑

---

## 🧪 测试验证

### 1. 自动化测试

运行合同和案件相关测试:

```bash
bundle exec rspec spec/requests/contracts_spec.rb spec/requests/cases_spec.rb --format documentation
```

**测试结果**: ✅ 16 examples, 0 failures

### 2. 功能验证

#### 测试场景

| 场景 | 文件类型 | 预览按钮 | 下载按钮 |
|------|---------|---------|---------|
| 合同主文件 | PDF | ✅ 浏览器内预览 | ✅ 触发下载 |
| 补充协议 | DOCX | ✅ Office Online 预览 | ✅ 触发下载 |
| 合同附件 | PNG | ✅ 模态框预览 | ✅ 触发下载 |
| 案件材料 | PDF | ✅ 浏览器内预览 | ✅ 触发下载 |

#### 预期行为

**预览按钮**:
- 图片: 使用 image-preview 模态框
- PDF: 在新标签页中打开（浏览器内置预览）
- Office 文件: 通过 Microsoft Office Online Viewer 预览
- 其他文件: 在新标签页中打开（inline）

**下载按钮**:
- 所有文件类型: 触发浏览器下载对话框
- 文件名: 保留原始文件名
- 行为: 通过 `Content-Disposition: attachment` 强制下载

---

## 📊 影响范围

### 修改的文件

```
modified:   app/helpers/application_helper.rb
```

### 受影响的功能

1. **合同详情页** (`app/views/contracts/show.html.erb`)
   - 主合同文件下载
   - 补充协议下载
   - 合同附件下载

2. **案件详情页** (`app/views/cases/show.html.erb`)
   - 案件材料下载

3. **所有使用 `smart_file_link` 的地方**
   - 设置 `action_buttons: true` 的附件展示

### 未受影响的功能

- ✅ 文件权限控制 (`secure_blobs_controller.rb`) - 未修改
- ✅ 预览功能 - 正常工作
- ✅ 文件删除功能 - 正常工作
- ✅ 文件上传功能 - 正常工作

---

## 🔒 安全性考虑

修复后的实现保持了原有的安全机制:

1. **权限验证**: 所有文件访问仍然通过 `SecureBlobsController` 进行权限检查
2. **签名验证**: 使用 ActiveStorage 的 `signed_id` 机制防止未授权访问
3. **路由隔离**: 预览和下载使用不同的路由，但都经过相同的权限验证流程

```ruby
# SecureBlobsController#show
def show
  blob = ActiveStorage::Blob.find_signed!(params[:signed_id])  # ✅ 签名验证
  attachment = ActiveStorage::Attachment.find_by!(blob_id: blob.id)
  record = attachment.record
  
  unless can_access_attachment?(record)  # ✅ 权限验证
    redirect_to root_path, alert: '您没有权限访问该文件'
    return
  end
  
  redirect_to rails_blob_path(blob, disposition: params[:disposition] || 'inline')
end
```

---

## 📝 相关文档

- [P2/P3 优化完成文档](./p2_p3_optimization_completed.md)
- [安全审计报告](./security_audit_report.md) - 附件安全部分
- [预览/下载按钮更新](./preview_download_buttons_update.md)

---

## 🎯 总结

### 问题本质

Helper 方法的路由选择逻辑错误，导致下载按钮使用了预览路由，使得 `disposition: 'attachment'` 参数被路由默认值覆盖。

### 解决方案

通过条件判断根据 `disposition` 参数选择正确的路由helper方法 (`secure_blob_path` vs `secure_blob_download_path`)，确保下载按钮使用专用的下载路由。

### 修复效果

- ✅ 下载按钮正常触发文件下载
- ✅ 预览按钮功能不受影响
- ✅ 所有测试通过
- ✅ 安全机制保持不变
- ✅ 代码简洁，易于维护

---

**修复时间**: 2026-03-15 09:38  
**修复人员**: AI Assistant  
**测试状态**: ✅ 通过  
**上线状态**: ✅ 已修复，待部署
