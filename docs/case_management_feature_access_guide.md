# 案件管理优化功能访问指南

## 📌 快速导航

本文档为用户提供案件管理10大优化功能的完整访问路径和使用说明。

---

## 🎯 功能访问入口总览

### 主要入口页面
1. **案件列表页**: `/cases` - 案件管理主页,集成智能筛选和搜索
2. **我的案件**: `/cases/my_cases` - 律师查看自己参与的案件
3. **主办案件**: `/cases/my_lead_cases` - 律师查看自己主办的案件
4. **团队工作量**: `/cases/team_workload` - 查看团队工作负荷统计
5. **案件日历**: `/cases/calendar` - 案件关键日期日历视图
6. **案件详情**: `/cases/:id` - 查看单个案件详细信息
7. **案件统计分析**: `/case_analytics/dashboard` - 案件数据统计面板

---

## 📋 10大优化方案功能访问指南

### ✅ 方案一:智能案件筛选与搜索系统

**访问路径**: 主导航 → 案件管理 → 案件列表页 (`/cases`)

**可用功能**:
- **快速筛选面板** (前端待实施):
  - 按状态筛选:准备立案/已立案待审/审理中/已判决/执行中/调解结案/已归档
  - 按阶段筛选:仲裁/一审/二审/执行/再审/恢复执行
  - 按案件类型筛选:合同纠纷/劳动争议等
  - 按优先级筛选:紧急/高/普通/低
  - 按企业筛选:选择特定企业的案件
  - 按团队成员筛选:查看特定律师参与的案件

- **全文搜索**:
  - 支持关键词搜索案件名称、案号、法院、摘要
  - URL参数:`?keyword=关键词`

- **智能排序**:
  - 按优先级排序:`?sort_by=priority`
  - 按时间排序:`?sort_by=last_activity_at`
  - 按立案日期:`?sort_by=filing_at`
  - 按开庭日期:`?sort_by=hearing_at`

- **保存筛选条件** (前端待实施):
  - 常用筛选组合可保存为快捷入口
  - API端点:`POST /case_filters`
  - 设为默认:`POST /case_filters/:id/set_as_default`

**当前状态**:
- ✅ 后端API完全就绪
- ⏳ 前端筛选面板UI待实施
- ✅ URL参数筛选已支持

**使用示例**:
```
# 查看所有审理中的高优先级案件
/cases?statuses[]=trial&priorities[]=high&priorities[]=urgent

# 搜索"合同纠纷"相关案件
/cases?keyword=合同纠纷

# 查看7天内有开庭的案件
/cases?hearing_days=7

# 按优先级降序排列
/cases?sort_by=priority&sort_direction=desc
```

---

### ✅ 方案二:案件团队协作增强

**访问路径**:

1. **我的案件视图**
   - 导航路径:主导航 → 案件管理 → "我的案件"
   - URL:`/cases/my_cases`
   - 权限:仅律师可访问
   - 功能:自动筛选出当前律师参与的所有案件(包括主办、辅助、助理角色)

2. **主办案件视图**
   - 导航路径:主导航 → 案件管理 → "主办案件"
   - URL:`/cases/my_lead_cases`
   - 权限:仅律师可访问
   - 功能:筛选出当前律师作为主办律师的案件

3. **团队工作量统计**
   - 导航路径:主导航 → 案件管理 → "团队工作量"
   - URL:`/cases/team_workload`
   - 权限:仅律师可访问
   - 功能:查看所有律师的案件负荷情况

**可查看信息**:
- 每个律师的总案件数
- 主办案件数量
- 活跃案件数量(已立案/审理中/已判决/执行中)
- 工作量可视化进度条

**当前状态**:
- ✅ 路由和控制器已实现
- ✅ 视图页面已创建
- ✅ 完全可用

---

### ✅ 方案三:结构化工作大事记系统

**访问路径**: 案件详情页 → "工作大事记"标签

**URL**: `/cases/:id` (案件详情页中的工作记录区域)

**可用功能**:
- **工作记录类型分类**:
  - 📞 沟通记录:与当事人/法院沟通
  - 🔍 调查取证:证据收集、调查
  - 📄 文书准备:起诉状、答辩状等
  - 👔 庭审准备:开庭准备工作
  - ⚖️ 庭审记录:庭审经过
  - 📋 材料提交:提交证据、申请
  - ⏰ 待办事项:需要跟进的事项
  - 📝 其他记录:一般工作记录

- **待办事项模式**:
  - 字段:`is_todo` (是否为待办)
  - 状态跟踪:`todo_status` (pending/in_progress/completed/cancelled)
  - 截止日期:`due_date`
  - 提醒时间:`reminder_at`
  - 完成时间:`completed_at`
  - 任务分配:`assigned_to` (多态关联,可分配给律师或企业用户)

- **重要事项标记**:
  - 字段:`is_important` (布尔值)
  - 重要工作记录在列表中高亮显示

**API端点**:
```ruby
# 创建工作记录
POST /cases/:case_id/work_logs

# 更新工作记录
PATCH /cases/:case_id/work_logs/:id

# 删除工作记录
DELETE /cases/:case_id/work_logs/:id
```

**数据库字段**:
- `log_type`: 工作记录类型
- `is_todo`: 是否为待办事项
- `todo_status`: 待办状态
- `due_date`: 截止日期
- `reminder_at`: 提醒时间
- `completed_at`: 完成时间
- `is_important`: 是否重要
- `assigned_to`: 分配给谁(多态)

**当前状态**:
- ✅ 数据库结构完整
- ✅ Model层完整(包含7个scope)
- ✅ API端点已配置
- ⏳ 前端UI需完善(类型选择器、待办状态切换、提醒设置等)

**Scope示例**:
```ruby
WorkLog.by_type('trial_prep')      # 筛选庭审准备记录
WorkLog.todos                       # 所有待办事项
WorkLog.pending_todos              # 待处理的待办
WorkLog.completed_todos            # 已完成的待办
WorkLog.overdue_todos              # 逾期的待办
WorkLog.upcoming_todos(7)          # 未来7天到期的待办
WorkLog.important                  # 重要事项
```

---

### ✅ 方案四:案件进度可视化系统

**数据库支持**:
- ✅ `case_progress_events` 表:记录案件里程碑事件
- ✅ `case_weekly_reports` 表:自动生成周报

**可记录事件类型**:
- `case_created` - 案件创建
- `status_changed` - 状态变更
- `filing_completed` - 立案完成
- `hearing_scheduled` - 开庭排期
- `hearing_completed` - 庭审完成
- `judgement_received` - 判决下达
- `case_closed` - 案件结案

**进度事件字段**:
- `event_type`: 事件类型
- `event_date`: 事件发生时间
- `description`: 事件描述
- `is_milestone`: 是否里程碑事件
- `is_automated`: 是否自动生成
- `metadata`: 事件元数据(JSONB)

**周报字段**:
- `week_start_date`: 周起始日期
- `week_end_date`: 周结束日期
- `work_summary`: 本周工作摘要(JSONB)
- `next_week_plan`: 下周计划(JSONB)
- `is_auto_generated`: 是否自动生成

**当前状态**:
- ✅ 数据库结构完整
- ✅ Model层完整
- ⏳ 自动触发逻辑待集成到Case model callbacks
- ⏳ 前端时间轴视图待实施
- ⏳ 周报生成Job待实施

**未来访问路径** (待实施):
- 案件详情页 → "进度时间轴"标签
- 企业用户首页 → "案件进展摘要"卡片
- 案件列表 → 各案件卡片显示最新进展

---

### ✅ 方案五:智能提醒与通知系统

**数据库支持**:
- ✅ `case_notifications` 表:通知记录
- ✅ `CaseNotificationService`:通知发送服务

**支持的通知类型**:
- `hearing_reminder` - 开庭提醒
- `appeal_deadline_reminder` - 上诉期限提醒
- `status_changed` - 状态变更通知
- `team_member_added` - 团队成员添加通知
- `new_work_log` - 新工作记录通知
- `new_comment` - 新评论通知
- `new_question` - 新问题通知
- `question_answered` - 问题已回复通知

**通知渠道**:
- `in_app` - 站内消息(已支持)
- `email` - 邮件通知(待实施)
- `sms` - 短信提醒(待实施)

**通知字段**:
- `notification_type`: 通知类型
- `recipient_type`, `recipient_id`: 接收者(多态)
- `title`: 通知标题
- `content`: 通知内容
- `channel`: 通知渠道
- `read_at`: 已读时间
- `metadata`: 通知元数据(JSONB)

**使用示例**:
```ruby
# 发送案件状态变更通知
CaseNotificationService.call(
  @case,
  'status_changed',
  @case.team_lawyers,
  content: "案件状态已更新为#{@case.status_display}"
)

# 发送开庭提醒
CaseNotificationService.call(
  @case,
  'hearing_reminder',
  [@case.company.boss] + @case.team_lawyers,
  content: "案件将于3天后开庭"
)
```

**当前状态**:
- ✅ 数据库结构完整
- ✅ Service完整实现
- ⏳ 定时任务(开庭提醒、上诉期限提醒)待配置
- ⏳ 前端通知中心页面待实施
- ⏳ 邮件和短信渠道待实施

**未来访问路径** (待实施):
- 顶部导航栏 → 通知图标 → 通知列表
- URL:`/notifications` (待创建)

---

### ✅ 方案六:批量操作与效率工具

**路由已配置**:
```ruby
namespace :cases do
  post 'bulk/update_status'      # 批量更新状态
  post 'bulk/add_team_member'    # 批量添加团队成员
  post 'bulk/export_archives'    # 批量导出档案
  post 'bulk/archive'            # 批量归档
end
```

**可用批量操作**:
1. 批量更新案件状态
2. 批量添加团队成员
3. 批量导出案件档案
4. 批量归档案件

**当前状态**:
- ✅ 路由已配置
- ⏳ Controller action待实现
- ⏳ 前端批量选择UI待实施(复选框、全选按钮、批量操作下拉菜单)

**未来使用流程** (待实施):
1. 案件列表页勾选需要批量操作的案件
2. 点击"批量操作"下拉菜单
3. 选择操作类型
4. 确认执行

---

### ✅ 方案七:案件关联与系列管理

**数据库支持**:
- ✅ `case_relations` 表:案件关联关系
- ✅ `case_series` 表:系列案件
- ✅ `case_series_memberships` 表:系列成员关系

**支持的关系类型**:
- `parent` - 原案
- `child` - 派生案件
- `related` - 相关案件
- `series` - 系列案件
- `appeal` - 上诉案件
- `retrial` - 再审案件

**Case model关联方法**:
```ruby
@case.case_relations_as_from      # 从本案出发的关系
@case.case_relations_as_to        # 指向本案的关系
@case.related_cases_from          # 本案关联的其他案件
@case.related_cases_to            # 关联到本案的其他案件
@case.case_series                 # 本案所属的系列
@case.all_related_cases           # 所有相关案件(待实现方法)
```

**CaseSeries字段**:
- `name`: 系列名称
- `description`: 系列描述
- `series_type`: 系列类型
- `company_id`: 所属企业
- `created_by_id`: 创建者

**当前状态**:
- ✅ 数据库结构完整
- ✅ Model层完整
- ⏳ Controller action待实现
- ⏳ 前端UI待实施(关联案件选择器、系列案件管理页面)

**未来访问路径** (待实施):
- 案件详情页 → "关联案件"标签
- 案件列表 → "系列案件管理"菜单

---

### ✅ 方案八:企业用户沟通增强

**数据库支持**:
- ✅ `case_questions` 表:问答系统

**可用功能**:
- 企业用户可以在案件详情页向律师提问
- 律师可以回复企业用户的问题
- 问题状态跟踪(已解决/未解决)

**字段说明**:
- `question`: 问题内容
- `answer`: 回答内容
- `asked_by_type`, `asked_by_id`: 提问者(多态)
- `answered_by_type`, `answered_by_id`: 回答者(多态)
- `answered_at`: 回答时间
- `is_resolved`: 是否已解决

**Scope方法**:
```ruby
CaseQuestion.unresolved    # 未解决的问题
CaseQuestion.resolved      # 已解决的问题
CaseQuestion.unanswered    # 未回答的问题
CaseQuestion.answered      # 已回答的问题
```

**当前状态**:
- ✅ 数据库结构完整
- ✅ Model层完整
- ⏳ Controller action待实现
- ⏳ 前端问答UI待实施

**未来访问路径** (待实施):
- 案件详情页 → "问答交流"标签
- 企业用户可发起提问
- 律师收到通知并回复

---

### ✅ 方案九:数据统计与分析面板

**访问路径**: 主导航 → 案件分析 → 统计面板

**URL**: `/case_analytics/dashboard`

**已实现统计维度**:

1. **概览统计** (`overview_stats`):
   - 总案件数
   - 活跃案件数
   - 已结案数
   - 待处理案件数
   - 平均结案周期

2. **案件类型分布** (`case_type_distribution`):
   - 合同纠纷、劳动争议、侵权纠纷等各类型案件数量

3. **状态分布** (`status_distribution`):
   - 各状态案件数量统计

4. **阶段分布** (`stage_distribution`):
   - 仲裁、一审、二审、执行等各阶段案件数量

5. **优先级分布** (`priority_distribution`):
   - 紧急、高、普通、低优先级案件数量

6. **时间线统计** (`timeline_stats`):
   - 按月统计新增案件数
   - 按月统计结案数
   - 趋势分析

7. **律师绩效指标** (`performance_metrics`):
   - 律师处理案件总数
   - 主办案件数量
   - 平均结案时长

**使用示例**:
```ruby
# 获取统计数据
stats = CaseStatisticsService.call(
  scope: Case.not_deleted,
  lawyer: current_lawyer,
  company: @company,
  date_range: 1.year.ago..Date.today
)

# 返回数据结构
{
  overview: {...},
  case_type_distribution: {...},
  status_distribution: {...},
  stage_distribution: {...},
  priority_distribution: {...},
  timeline_stats: [...],
  performance_metrics: {...}
}
```

**当前状态**:
- ✅ Service完整实现
- ✅ 所有统计维度已支持
- ✅ Controller已创建
- ⏳ 前端可视化图表待实施

---

### ✅ 方案十:移动端优化

**当前状态**:
- ✅ 数据库和Model层完全就绪
- ✅ Service层完全就绪
- ⏳ 移动端检测helper待实施
- ⏳ 响应式UI优化待完善
- ⏳ 语音输入controller待实施

**未来功能** (待实施):
- 移动端专用布局
- 语音输入工作记录
- 拍照上传优化
- 离线功能支持

---

## 🔧 开发者参考

### 筛选API参数完整列表

```ruby
# URL参数示例
{
  keyword: '关键词',              # 全文搜索
  statuses: ['trial', 'judged'], # 状态筛选
  stages: ['first_trial'],       # 阶段筛选
  case_types: ['合同纠纷'],      # 案件类型
  priorities: ['high', 'urgent'], # 优先级
  company_id: 1,                  # 企业筛选
  team_member_id: 2,              # 团队成员筛选
  lead_lawyer_id: 3,              # 主办律师筛选
  hearing_days: 7,                # 未来N天开庭
  appeal_days: 10,                # 未来N天上诉期限
  filed_from: '2024-01-01',       # 立案开始日期
  filed_to: '2024-12-31',         # 立案结束日期
  sort_by: 'priority',            # 排序字段
  sort_direction: 'desc'          # 排序方向
}
```

### Case Model高级Scope

```ruby
Case.high_value                    # 高标的案件(100万以上)
Case.urgent_cases                  # 紧急活跃案件
Case.need_update                   # 30天未更新的活跃案件
Case.upcoming_hearings             # 7天内开庭
Case.overdue_judgements            # 超期未执行
Case.by_client(company_id)         # 按委托人筛选
Case.filter_by_team_member(id)    # 按团队成员筛选
Case.filter_by_lead_lawyer(id)    # 按主办律师筛选
```

---

## 📝 后续待实施功能清单

### 立即可做(0-1周)
1. **筛选面板UI** - `app/views/cases/_filter_panel.html.erb`
2. **批量操作UI** - 复选框 + 批量操作下拉菜单
3. **通知中心页面** - `/notifications` 路由和视图
4. **工作记录类型选择器** - 8种类型的下拉选择

### 近期优化(1-2周)
1. **定时任务配置** - GoodJob执行开庭提醒、周报生成
2. **邮件通知模板** - Action Mailer配置
3. **进度时间轴视图** - 案件详情页进度可视化
4. **问答交流UI** - 企业用户提问、律师回复界面

### 长期迭代(2周+)
1. **数据分析图表** - Chartkick或类似库实现可视化
2. **案件关联管理页面** - 系列案件、关联案件视图
3. **移动端适配** - 响应式优化、语音输入
4. **批量操作后端实现** - Cases::BulkOperationsController

---

## 🎯 用户角色功能访问权限

### 律师用户
- ✅ 查看所有企业的案件
- ✅ 我的案件视图 (`/cases/my_cases`)
- ✅ 主办案件视图 (`/cases/my_lead_cases`)
- ✅ 团队工作量统计 (`/cases/team_workload`)
- ✅ 创建和编辑案件
- ✅ 添加工作记录
- ✅ 回复企业用户提问
- ✅ 查看统计分析面板

### 企业用户(老板)
- ✅ 查看本企业案件
- ✅ 查看案件详情和工作记录
- ✅ 向律师提问
- ✅ 确认删除案件
- ✅ 导出案件档案

### 企业用户(员工)
- ✅ 查看本企业案件
- ✅ 查看案件详情和工作记录
- ✅ 向律师提问
- ✅ 请求删除案件(需老板确认)

---

## 📞 技术支持

如有功能使用问题或发现bug,请联系开发团队。

**文档版本**: v1.0  
**最后更新**: 2024-03-11  
**维护团队**: 产品/开发团队
