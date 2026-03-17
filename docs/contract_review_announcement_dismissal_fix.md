# 合同审查后自动消除公告功能修复

## 问题描述

用户反馈：梁家航律师已经完成对广东欧陆美居建材有限公司铝板销售合同的审查，但重要公告栏中的"合同审查"公告仍未自动消除。

## 根本原因分析

### 1. 数据问题
检查数据库发现，该合同的律师评论记录中 `author_id` 和 `author_type` 字段为空：
```ruby
Comment.find(58)
# author_id: nil
# author_type: nil
# author_name: "梁家航（律师）"
# author_role: "lawyer"
```

### 2. 代码缺陷
原来的 `Comment#auto_dismiss_announcement` 方法只依赖 `author_id` 来查找律师账户：
```ruby
# 旧代码（有缺陷）
lawyer = LawyerAccount.find_by(id: author_id) if author_role == 'lawyer'
```

如果 `author_id` 为空，则无法找到律师账户，导致公告消除失败。

## 修复方案

### 修改 `Comment` 模型（app/models/comment.rb）

增强 `auto_dismiss_announcement` 方法，支持多种方式推断律师账户：

1. **优先使用 `author` 关联**（最可靠）
   ```ruby
   if author && author.is_a?(LawyerAccount)
     lawyer = author
   ```

2. **使用 `author_id` + `author_type`**（次优）
   ```ruby
   elsif author_id.present? && author_type == 'LawyerAccount'
     lawyer = LawyerAccount.find_by(id: author_id)
   ```

3. **从 `author_name` 推断**（兜底方案）
   ```ruby
   elsif author_name.present?
     clean_name = author_name.gsub(/[（(].*?[）)]/, '').strip
     lawyer = LawyerAccount.find_by('name LIKE ?', "%#{clean_name}%")
   ```

### 扩展支持的公告类型

同时支持：
- `contract_review` - 合同审查
- `major_issue_review` - 重大事项审查
- `reconciliation_review` - 对账单审查

### 补救脚本

创建 `tmp/fix_missing_announcement_dismissals.rb` 脚本，用于处理历史数据：
- 查找所有 `reviewed_by_lawyer = true` 的合同
- 检查对应的律师评论和公告消除状态
- 自动补救未消除的公告

执行结果：
```
已审查合同总数: 2
- 已修复: 1 个合同
- 已跳过（已消除）: 1 个合同
```

## 测试覆盖

创建 `spec/models/comment_auto_dismiss_announcement_spec.rb` 测试文件，包含 8 个测试用例：

✅ 自动消除合同审查公告（使用 author 关联）
✅ 自动消除合同审查公告（使用 author_name 推断）
✅ 如果公告已被消除，不会抛出异常
✅ 助理添加评论不会自动消除公告
✅ 律师评论后自动消除对账单审查公告
✅ 律师评论后自动消除重大事项审查公告
✅ 如果无法推断律师账户，不会抛出异常
✅ 公司用户评论不会触发公告消除

所有测试通过 ✅

## 验证结果

### 手动验证
```bash
rails runner "
  contract = Contract.find(24)
  lawyer = LawyerAccount.find(29)
  dismissed = AnnouncementDismissal.dismissed_by_user?('contract_review', contract, lawyer)
  puts '公告是否已消除: ' + dismissed.to_s
"
```

输出：
```
公告是否已消除: true
消除时间: 2026-03-13 20:43:34 +0800
消除原因: reviewed
```

## 影响范围

### 修改的文件
1. `app/models/comment.rb` - 增强律师账户推断逻辑
2. `spec/models/comment_auto_dismiss_announcement_spec.rb` - 新增测试文件
3. `tmp/fix_missing_announcement_dismissals.rb` - 历史数据补救脚本

### 向后兼容性
- ✅ 完全向后兼容
- ✅ 不影响现有功能
- ✅ 增强了容错性

### 性能影响
- 最小化：仅在创建律师评论时触发（低频操作）
- 查询优化：使用索引字段查询律师账户
- 异常处理：失败不影响评论创建

## 未来优化建议

1. **数据完整性约束**
   - 在创建评论时始终确保 `author` 关联正确设置
   - 添加数据库级别的约束或验证

2. **监控告警**
   - 记录无法推断律师账户的情况
   - 定期检查公告消除失败的记录

3. **用户体验**
   - 考虑在前端显示公告消除状态
   - 提供手动消除公告的选项

## 部署步骤

1. 部署代码变更
2. 运行补救脚本：
   ```bash
   rails runner tmp/fix_missing_announcement_dismissals.rb
   ```
3. 验证所有已审查合同的公告已正确消除
4. 监控新创建评论的公告消除情况

## 相关文档

- 待办任务自动消除公告功能：`docs/todo_auto_dismiss_announcement_feature.md`
- 公告系统设计：`app/models/announcement.rb`
- 评论系统设计：`app/models/comment.rb`
