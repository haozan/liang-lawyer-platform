# 公告自动消除功能 - 角色支持完善

## 问题描述

用户反馈：梁家航律师（team_leader 角色）已完成对铝板销售合同的审查并添加了评论，但首页重要公告栏中的"合同审查"公告仍未自动消除。

## 根本原因分析

### 1. 初始问题（已于 2026-03-13 修复）
- **问题**：`Comment#auto_dismiss_announcement` 方法只检查 `author_role == 'lawyer'`
- **影响**：其他律师角色（team_leader、senior_lawyer、super_admin）的评论不会触发自动消除
- **修复**：将检查条件改为 `author_role.in?(['lawyer', 'senior_lawyer', 'team_leader', 'super_admin'])`

### 2. 本次发现的问题
虽然 `auto_dismiss_announcement` 方法本身已支持多角色，但回调条件 `if: :lawyer_comment?` 仍然只匹配 `'lawyer'` 角色。

#### 问题代码（app/models/comment.rb）
```ruby
# Line 22-23: Callbacks
after_create :mark_reviewed_by_lawyer, if: :lawyer_comment?
after_create :auto_dismiss_announcement, if: :lawyer_comment?

# Line 66-68: 条件方法
def lawyer_comment?
  author_role == 'lawyer'  # ❌ 只匹配 'lawyer'
end
```

**结果**：当 `author_role` 为 `'team_leader'`、`'senior_lawyer'` 或 `'super_admin'` 时，回调根本不会执行。

## 解决方案

### 修复 `lawyer_comment?` 方法（app/models/comment.rb）

```ruby
def lawyer_comment?
  author_role.in?(['lawyer', 'senior_lawyer', 'team_leader', 'super_admin'])
end
```

### 修复后的完整逻辑流程

1. **评论创建**时，`lawyer_comment?` 检查是否为律师角色
2. **如果是律师角色**，触发 `after_create` 回调：
   - `mark_reviewed_by_lawyer`: 标记资源为"已审查"
   - `auto_dismiss_announcement`: 自动消除相关公告
3. **自动消除逻辑**：
   - 确定公告类型（contract_review、major_issue_review、reconciliation_review）
   - 推断律师账户（优先使用 author 关联 → author_id/type → author_name）
   - 调用 `AnnouncementDismissal.dismiss!` 创建消除记录
4. **首页公告过滤**：
   - `AnnouncementService#filter_dismissed_announcements` 过滤已消除的公告
   - 首页不再显示已消除的公告

## 测试覆盖

创建了 `spec/models/comment_auto_dismiss_announcement_spec.rb`，包含 10 个测试用例：

### 测试场景

1. **普通律师（lawyer）**
   - ✅ 使用 author 关联自动消除公告
   - ✅ 使用 author_name 推断自动消除公告
   - ✅ 公告已消除时不抛出异常

2. **团队负责人（team_leader）**
   - ✅ 评论后自动消除合同审查公告

3. **资深律师（senior_lawyer）**
   - ✅ 评论后自动消除合同审查公告

4. **律师助理（assistant）**
   - ✅ 评论后不会自动消除公告

5. **对账单审查**
   - ✅ 律师评论后自动消除对账单审查公告

6. **重大事项审查**
   - ✅ 律师评论后自动消除重大事项审查公告

7. **边界情况**
   - ✅ 无法推断律师账户时不抛出异常
   - ✅ 公司用户评论不触发公告消除

### 测试结果

```bash
$ bundle exec rspec spec/models/comment_auto_dismiss_announcement_spec.rb
10 examples, 0 failures
```

## 历史数据处理

对于已存在的评论（如梁家航律师对合同 ID 28 的评论），使用以下命令手动消除公告：

```ruby
rails runner "
  contract = Contract.find(28)
  lawyer = LawyerAccount.find_by(name: '梁家航')
  
  AnnouncementDismissal.dismiss!(
    announcement_type: 'contract_review',
    related: contract,
    user: lawyer,
    reason: 'reviewed'
  )
"
```

## 验证结果

```bash
$ rails runner "验证脚本"
👨‍⚖️ 律师: 梁家航 (team_leader)
📢 公告总数: 0
📝 合同审查公告数: 0
✅ 已无合同审查公告！首页重要公告栏已清空。
```

## 影响范围

### 修改的文件

1. **app/models/comment.rb**
   - 修复 `lawyer_comment?` 方法支持所有律师角色

2. **spec/models/comment_auto_dismiss_announcement_spec.rb**
   - 新增测试用例：团队负责人、资深律师角色测试

### 向后兼容性

✅ 完全向后兼容，现有功能不受影响：
- `spec/requests/comments_spec.rb`: 1/1 通过
- `spec/models/comment_auto_dismiss_announcement_spec.rb`: 10/10 通过

## 部署说明

### 前置条件

无需数据库迁移，仅代码更新。

### 部署步骤

1. **更新代码**：
   ```bash
   git pull origin main
   ```

2. **重启应用**：
   ```bash
   bin/dev
   ```

3. **验证功能**：
   - 使用不同角色的律师账户登录
   - 对待审查合同添加评论
   - 确认首页公告栏自动消除

## 未来优化建议

1. **统一角色判断方法**
   - 在 `LawyerAccount` 模型中提供统一的 `lawyer_roles` 常量
   - 避免在多处硬编码角色列表

2. **增强测试覆盖**
   - 添加集成测试验证首页公告显示
   - 测试多个合同同时审查的场景

3. **监控与日志**
   - 添加公告消除失败的监控报警
   - 记录自动消除的审计日志

## 相关文档

- [合同审查自动消除公告修复（2026-03-13）](./contract_review_announcement_dismissal_fix.md)
- [待办任务自动消除公告功能](./todo_auto_dismiss_announcement_feature.md)

---

**修复时间**：2026-03-13  
**修复人员**：AI Assistant  
**问题类型**：角色权限支持不完整  
**严重程度**：中等（影响非 lawyer 角色的律师）
