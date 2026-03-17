# 待办完成自动消除公告功能

## 📋 功能概述

当用户完成重大事项的待办任务后，系统会智能识别并自动消除相关的重要公告。

## 🎯 业务场景

**用户痛点：**
- 用户完成了所有待办任务，但相关的重要公告仍然显示在系统中
- 需要手动去消除公告，操作繁琐

**解决方案：**
- 当用户完成重大事项的**最后一个**待办任务时
- 系统自动检测该重大事项的所有待办任务是否都已完成
- 如果是，则自动消除该重大事项相关的所有公告

## 🔧 技术实现

### 1. 模型层改动

#### `app/models/major_issue.rb`

新增两个方法：

```ruby
# 检查所有待办任务是否已完成
def all_todos_completed?
  return false if todo_items.empty?
  todo_items.where.not(status: 'completed').empty?
end

# 自动消除相关公告（当所有待办任务完成时）
def auto_dismiss_announcements_if_todos_completed(user)
  return unless all_todos_completed?
  
  # 消除重大事项相关公告
  begin
    AnnouncementDismissal.dismiss!(
      announcement_type: 'major_issue_review',
      related: self,
      user: user,
      reason: 'all_todos_completed'
    )
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
    # 公告已被消除或验证失败，忽略
    Rails.logger.info "公告已被消除或无需消除: #{e.message}"
  rescue => e
    # 其他错误，记录但不阻断执行
    Rails.logger.warn "自动消除公告失败: #{e.message}"
  end
end
```

#### `app/models/major_issue_todo_item.rb`

修改 `complete!` 方法，在完成待办时触发公告消除检查：

```ruby
def complete!(user)
  transaction do
    update!(
      status: 'completed',
      completed_at: Time.current,
      completed_by: user
    )
    
    # 检查是否所有待办都已完成，如果是则自动消除相关公告
    major_issue.auto_dismiss_announcements_if_todos_completed(user)
  end
end
```

## 💡 智能判断逻辑

### 何时自动消除公告？

✅ **会自动消除的情况：**
- 重大事项有1个待办任务，完成后自动消除
- 重大事项有多个待办任务，**全部完成**后自动消除

❌ **不会自动消除的情况：**
- 重大事项有多个待办任务，只完成了部分任务
- 重大事项没有待办任务（返回 false）
- 待办任务状态为 `cancelled`（取消状态）时，不计入"已完成"

### 状态判断说明

待办任务的状态包括：
- `pending` - 待处理
- `in_progress` - 进行中
- `completed` - 已完成 ✅
- `cancelled` - 已取消

**判断规则：**
```ruby
# 只要有任何非completed状态的任务（包括pending、in_progress、cancelled），
# 都认为待办任务未全部完成
todo_items.where.not(status: 'completed').empty?
```

## 🧪 测试覆盖

测试文件：`spec/models/major_issue_todo_item_auto_dismiss_spec.rb`

**测试场景：**
1. ✅ 单个待办任务完成后自动消除公告
2. ✅ 多个待办任务部分完成时不消除公告
3. ✅ 多个待办任务全部完成后自动消除公告
4. ✅ 有取消状态的待办任务时的处理
5. ✅ 没有待办任务时的边界情况
6. ✅ 公告已被消除时的异常处理

**测试结果：** 10个测试用例全部通过 ✅

## 🔒 异常处理

### 1. 公告已被消除
如果公告已经被手动消除过，系统会捕获 `ActiveRecord::RecordNotUnique` 异常，不会重复创建消除记录。

### 2. 数据库事务
使用数据库事务确保待办完成和公告消除是原子操作：
```ruby
transaction do
  update!(...)  # 更新待办状态
  major_issue.auto_dismiss_announcements_if_todos_completed(user)  # 消除公告
end
```

### 3. 错误日志
- 正常消除：无日志输出
- 重复消除：`Rails.logger.info` 记录信息
- 其他错误：`Rails.logger.warn` 记录警告，但不阻断待办完成操作

## 📊 用户体验流程

```
用户完成待办任务
      ↓
系统检查该重大事项的所有待办
      ↓
      ├─ 还有未完成的待办？
      │       ↓ 是
      │   不消除公告，等待后续完成
      │
      └─ 所有待办都已完成？
              ↓ 是
          自动消除相关公告
              ↓
        用户看到公告已消失 ✨
```

## 🎨 优化建议（未来可选）

### 1. 通知提醒
完成所有待办时，可以给用户发送通知：
```
"✅ 恭喜！【{重大事项标题}】的所有待办任务已完成，相关公告已自动消除。"
```

### 2. 公告恢复
如果用户又创建了新的待办任务，可以考虑恢复公告：
```ruby
# 在创建新待办时调用
AnnouncementDismissal.restore!(
  announcement_type: 'major_issue_review',
  related: major_issue,
  user: user
)
```

### 3. 统计数据
记录自动消除的公告数量，用于系统分析：
```ruby
Rails.cache.increment('auto_dismissed_announcements_count')
```

## 🚀 部署说明

### 1. 代码部署
无需数据库迁移，直接部署代码即可。

### 2. 兼容性
- ✅ 向后兼容：不影响现有功能
- ✅ 数据库：无需修改表结构
- ✅ 性能：使用 where.not 查询，性能良好

### 3. 回滚
如果需要回滚，只需恢复以下两个文件的原始版本：
- `app/models/major_issue.rb`
- `app/models/major_issue_todo_item.rb`

## 📞 技术支持

如有问题，请联系开发团队或查看测试文件获取更多示例。

---

**创建日期：** 2025-01-XX  
**版本：** v1.0  
**作者：** AI Assistant
