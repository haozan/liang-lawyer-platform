# 重大事项讨论板块 - 综合优化实施路线图

## 📅 实施时间表

### Week 1-2: 核心协作功能 (Phase 1)
**目标**: 实现真正的多方实时协作讨论

#### Task 1.1: 评论权限扩展
- [x] Comment模型支持polymorphic author（lawyer + company_user）
- [x] 修改CommentsController权限检查
- [x] 更新评论表单（企业用户可见）
- [x] 测试：企业用户发表评论

#### Task 1.2: @提醒机制
- [ ] 添加mentioned_user_ids字段到comments表
- [ ] 实现@username解析逻辑
- [ ] 创建CommentMention关联表
- [ ] 通知被@用户（邮件+站内）
- [ ] 前端：@输入时自动补全用户列表

#### Task 1.3: 实时推送系统
- [ ] 创建MajorIssueChannel（ActionCable）
- [ ] 实现新评论实时广播
- [ ] 实现"正在输入"状态
- [ ] 前端：Stimulus controller处理实时消息
- [ ] 音效+桌面通知

#### Task 1.4: 未读状态追踪
- [ ] 创建major_issue_read_statuses表
- [ ] 实现未读计数逻辑
- [ ] 列表页显示"X条新回复"徽章
- [ ] 详情页高亮未读评论
- [ ] 自动标记已读

**验收标准**:
- ✅ 企业用户可以发表评论并上传附件
- ✅ @某人后该用户收到实时通知
- ✅ 新评论实时出现在所有在线用户界面
- ✅ 未读徽章准确显示
- ✅ 全部测试通过

---

### Week 3-4: 智能状态管理 (Phase 2A)

#### Task 2.1: 自动状态流转
- [ ] 集成AASM状态机
- [ ] 第一条评论时自动 pending → discussing
- [ ] 标记解决时自动更新resolved_at
- [ ] 状态变更广播（ActionCable）
- [ ] 状态变更日志

#### Task 2.2: 进度追踪
- [ ] 添加processing_days字段
- [ ] 定时任务每日更新processing_days
- [ ] 实现overdue?和overdue_days方法
- [ ] 详情页显示进度条+超时警告
- [ ] 计算平均处理时长

#### Task 2.3: 智能提醒系统
- [ ] 创建MajorIssueReminderJob
- [ ] 紧急事项1天未处理提醒
- [ ] 讨论中7天无回复提醒
- [ ] 待律师答复超时提醒
- [ ] 配置定时任务（每日9am）

#### Task 2.4: 快捷操作按钮
- [ ] 详情页顶部添加状态操作组
- [ ] "开始讨论"按钮
- [ ] "标记解决"按钮（含结论表单）
- [ ] "归档"按钮
- [ ] 操作权限控制

**验收标准**:
- ✅ 状态自动流转无需手动编辑
- ✅ 超时事项正确显示警告
- ✅ 提醒任务按时执行并发送通知
- ✅ 快捷按钮根据状态和权限显示
- ✅ 全部测试通过

---

### Week 5-6: 知识沉淀与搜索 (Phase 2B)

#### Task 3.1: 决策记录
- [ ] 添加conclusion字段到major_issues表
- [ ] 标记解决时必填结论
- [ ] 详情页顶部高亮显示决策结论
- [ ] 结论模板库
- [ ] 导出时包含结论

#### Task 3.2: 置顶与关键意见
- [ ] 添加is_pinned、pinned_at字段到comments
- [ ] 实现置顶/取消置顶功能
- [ ] 添加is_key_opinion字段
- [ ] 详情页分区显示（置顶/关键/普通）
- [ ] 权限：律师+老板可置顶

#### Task 3.3: 高级筛选系统
- [ ] 创建saved_filters表
- [ ] 实现多条件组合查询
- [ ] 快捷标签：待讨论/讨论中/紧急等
- [ ] 保存常用筛选条件
- [ ] 筛选器管理（编辑/删除）

#### Task 3.4: 关注功能
- [ ] 创建major_issue_followers表
- [ ] "关注"按钮（star icon）
- [ ] "我关注的"筛选标签
- [ ] 关注事项有新动态时通知
- [ ] 关注者列表显示

**验收标准**:
- ✅ 已解决事项都有完整结论
- ✅ 关键意见醒目展示
- ✅ 筛选快速准确
- ✅ 关注功能正常工作
- ✅ 全部测试通过

---

### Week 7-8: 附件与协作集成 (Phase 3)

#### Task 4.1: 附件分类管理
- [ ] 创建major_issue_attachments表
- [ ] 附件上传时选择分类
- [ ] 详情页按分类分组显示
- [ ] 版本号自动递增
- [ ] 标记最新版本

#### Task 4.2: 附件批量操作
- [ ] 批量下载（zip打包）
- [ ] 批量删除
- [ ] 附件搜索
- [ ] 历史版本查看
- [ ] Office文件在线预览

#### Task 4.3: 模块关联
- [ ] 添加related_record polymorphic关联
- [ ] 关联到Contract/Case
- [ ] 详情页显示关联记录
- [ ] 快速跳转
- [ ] 双向关联显示

#### Task 4.4: 待办快速创建
- [ ] 创建major_issue_todo_items表
- [ ] 讨论区"创建待办"表单
- [ ] 待办列表显示
- [ ] 待办状态切换
- [ ] 到期提醒

#### Task 4.5: 外部分享
- [ ] 添加share_token、share_expires_at字段
- [ ] 生成分享链接（7天有效）
- [ ] 分享页面布局（只读）
- [ ] 过期处理
- [ ] 访问统计

**验收标准**:
- ✅ 附件分类清晰可管理
- ✅ 批量操作流畅
- ✅ 关联记录准确显示
- ✅ 待办创建方便
- ✅ 分享链接可用
- ✅ 全部测试通过

---

### Week 9-10: 数据分析与移动端 (Phase 4)

#### Task 5.1: 统计仪表板
- [ ] 创建analytics action
- [ ] 计算KPI指标
- [ ] 平均处理时长趋势图
- [ ] 事项类型分布饼图
- [ ] 律师工作量统计表

#### Task 5.2: 预警系统
- [ ] 超时事项统计
- [ ] 长期未解决事项
- [ ] 讨论停滞事项
- [ ] 预警卡片显示
- [ ] 预警通知

#### Task 5.3: 报表导出
- [ ] 月度报告生成
- [ ] 季度报告生成
- [ ] Excel导出
- [ ] PDF导出
- [ ] 定期自动发送

#### Task 5.4: 移动端优化
- [ ] 列表页响应式布局
- [ ] 详情页移动端适配
- [ ] 滑动操作手势
- [ ] 底部悬浮操作按钮
- [ ] 语音输入（可选）

#### Task 5.5: 性能优化
- [ ] 数据库索引优化
- [ ] N+1查询优化
- [ ] 缓存策略
- [ ] 分页性能
- [ ] ActionCable性能调优

**验收标准**:
- ✅ 数据统计准确完整
- ✅ 图表清晰易读
- ✅ 移动端体验流畅
- ✅ 页面加载 < 2秒
- ✅ 全部测试通过

---

## 🗂️ 数据库迁移清单

### Migration 1: 评论权限扩展
```ruby
class UpdateCommentsForMultipleAuthors < ActiveRecord::Migration[7.2]
  def change
    # 评论作者改为polymorphic
    change_column_null :comments, :author_id, true
    add_column :comments, :author_type, :string
    add_index :comments, [:author_type, :author_id]
    
    # @提醒
    add_column :comments, :mentioned_user_ids, :jsonb, default: []
    add_index :comments, :mentioned_user_ids, using: :gin
    
    # 置顶与关键意见
    add_column :comments, :is_pinned, :boolean, default: false
    add_column :comments, :pinned_at, :datetime
    add_column :comments, :pinned_by_id, :integer
    add_column :comments, :is_key_opinion, :boolean, default: false
    
    add_index :comments, :is_pinned
    add_index :comments, :is_key_opinion
  end
end
```

### Migration 2: 重大事项增强
```ruby
class EnhanceMajorIssues < ActiveRecord::Migration[7.2]
  def change
    add_column :major_issues, :conclusion, :text
    add_column :major_issues, :processing_days, :integer, default: 0
    add_column :major_issues, :followers_count, :integer, default: 0
    add_column :major_issues, :views_count, :integer, default: 0
    add_column :major_issues, :related_record_type, :string
    add_column :major_issues, :related_record_id, :integer
    add_column :major_issues, :share_token, :string
    add_column :major_issues, :share_expires_at, :datetime
    
    add_index :major_issues, [:related_record_type, :related_record_id]
    add_index :major_issues, :share_token, unique: true
    add_index :major_issues, :processing_days
  end
end
```

### Migration 3: 附件管理
```ruby
class CreateMajorIssueAttachments < ActiveRecord::Migration[7.2]
  def change
    create_table :major_issue_attachments do |t|
      t.references :major_issue, foreign_key: true, null: false
      t.string :category, null: false  # contract/financial/evidence/legal/other
      t.integer :version, default: 1
      t.string :original_filename
      t.bigint :active_storage_blob_id
      t.boolean :is_latest, default: true
      
      t.timestamps
    end
    
    add_index :major_issue_attachments, :category
    add_index :major_issue_attachments, :active_storage_blob_id
    add_index :major_issue_attachments, [:major_issue_id, :original_filename, :version], 
              name: 'index_attachments_on_issue_and_filename_and_version'
  end
end
```

### Migration 4: 关注与阅读状态
```ruby
class CreateMajorIssueFollowersAndReadStatuses < ActiveRecord::Migration[7.2]
  def change
    create_table :major_issue_followers do |t|
      t.references :major_issue, foreign_key: true, null: false
      t.references :user, polymorphic: true, null: false
      t.boolean :notify_new_comment, default: true
      t.boolean :notify_status_change, default: true
      
      t.timestamps
    end
    
    add_index :major_issue_followers, [:major_issue_id, :user_type, :user_id], 
              unique: true, 
              name: 'index_followers_on_issue_and_user'
    
    create_table :major_issue_read_statuses do |t|
      t.references :major_issue, foreign_key: true, null: false
      t.references :user, polymorphic: true, null: false
      t.datetime :last_read_at
      t.integer :last_read_comment_id
      t.integer :unread_count, default: 0
      
      t.timestamps
    end
    
    add_index :major_issue_read_statuses, [:major_issue_id, :user_type, :user_id], 
              unique: true, 
              name: 'index_read_statuses_on_issue_and_user'
  end
end
```

### Migration 5: 待办与筛选
```ruby
class CreateMajorIssueTodoItemsAndSavedFilters < ActiveRecord::Migration[7.2]
  def change
    create_table :major_issue_todo_items do |t|
      t.references :major_issue, foreign_key: true, null: false
      t.string :title, null: false
      t.text :description
      t.string :status, default: 'pending'
      t.references :assignee, polymorphic: true
      t.date :due_date
      t.datetime :completed_at
      
      t.timestamps
    end
    
    add_index :major_issue_todo_items, :status
    add_index :major_issue_todo_items, :due_date
    
    create_table :saved_filters do |t|
      t.references :user, polymorphic: true, null: false
      t.string :name, null: false
      t.jsonb :conditions, default: {}
      t.string :filterable_type, null: false
      t.boolean :is_default, default: false
      
      t.timestamps
    end
    
    add_index :saved_filters, [:user_type, :user_id, :filterable_type]
    add_index :saved_filters, :conditions, using: :gin
  end
end
```

---

## 🧪 测试策略

### 单元测试 (RSpec)
- MajorIssue model: 状态机、进度计算、超时判断
- Comment model: @解析、置顶逻辑
- MajorIssueAttachment: 版本管理
- MajorIssueFollower: 关注/取消关注
- SavedFilter: 条件序列化/反序列化

### 功能测试 (Request Specs)
- CommentsController: 多角色评论权限
- MajorIssuesController: CRUD + 状态操作
- 筛选功能: 多条件组合
- 分享链接: 访问控制、过期处理

### 集成测试 (System Tests - 可选)
- 实时评论推送
- @提醒流程
- 滑动操作
- 移动端布局

### 性能测试
- 1000+事项列表加载时间
- 100+评论详情页加载
- 复杂筛选查询性能
- ActionCable并发连接

---

## 📊 监控指标

### 业务指标
- 日活跃用户数（DAU）
- 新增事项数
- 平均处理时长
- 评论参与率
- 解决率

### 技术指标
- 页面加载时间（P95）
- API响应时间
- ActionCable连接数
- 数据库慢查询
- 错误率

### 用户体验指标
- 移动端使用占比
- 搜索使用频率
- 筛选保存率
- 分享链接访问量

---

## 🚀 部署计划

### 灰度发布策略
1. **Alpha (Week 11)**: 内部测试（开发团队）
2. **Beta (Week 12)**: 小范围用户测试（5-10个企业）
3. **RC (Week 13)**: 大范围测试（50%用户）
4. **GA (Week 14)**: 全量发布

### 回滚策略
- 数据库迁移可逆
- Feature Flag控制新功能
- 旧版本保留7天

### 监控告警
- 错误率 > 1% 告警
- 响应时间 > 3s 告警
- ActionCable断连 > 10% 告警

---

## 📚 文档清单

- [x] 综合优化方案文档
- [x] 实施路线图
- [ ] API文档（如需对外）
- [ ] 用户使用手册
- [ ] 管理员配置指南
- [ ] 开发者维护文档
- [ ] 测试用例文档

---

## ✅ 验收检查清单

### 功能完整性
- [ ] 所有8个优化模块功能完整
- [ ] 权限控制正确无漏洞
- [ ] 数据一致性保证
- [ ] 边界情况处理

### 性能要求
- [ ] 列表页加载 < 2s
- [ ] 详情页加载 < 1.5s
- [ ] 实时消息延迟 < 500ms
- [ ] 数据库查询优化

### 兼容性
- [ ] Chrome/Firefox/Safari最新版
- [ ] iOS Safari 14+
- [ ] Android Chrome 90+
- [ ] 桌面端 1920x1080 ~ 移动端 375x667

### 代码质量
- [ ] 测试覆盖率 ≥ 80%
- [ ] 无Rubocop警告
- [ ] 无N+1查询
- [ ] 代码审查通过

### 用户体验
- [ ] 操作流程顺畅
- [ ] 反馈及时明确
- [ ] 错误提示友好
- [ ] 移动端体验良好

---

## 🎯 项目里程碑

| 里程碑 | 时间 | 交付物 | 责任人 |
|--------|------|--------|--------|
| M1: 核心协作 | Week 2 | 多方讨论+实时推送 | AI Assistant |
| M2: 智能管理 | Week 4 | 状态流转+提醒系统 | AI Assistant |
| M3: 知识沉淀 | Week 6 | 决策记录+高级筛选 | AI Assistant |
| M4: 深度集成 | Week 8 | 附件管理+模块关联 | AI Assistant |
| M5: 数据驱动 | Week 10 | 统计分析+移动优化 | AI Assistant |
| M6: 全量上线 | Week 14 | 生产环境稳定运行 | PM + AI Assistant |

---

## 📞 支持与反馈

遇到问题或建议？
- 📧 Email: support@example.com
- 💬 Slack: #major-issue-optimization
- 📝 Issue: GitHub Issues

---

**最后更新**: 2025-01-XX
**文档版本**: v1.0
**维护者**: AI Assistant
