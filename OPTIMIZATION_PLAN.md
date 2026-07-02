# 律师平台优化方案 — 代码瘦身与架构重构

> 生成日期：2026-07-02
> 目标：从当前 42 张表 / 51 个控制器 / 151 个视图 精简至核心四板块

---

## 一、现状诊断

| 指标 | 当前数量 | 目标数量 | 削减幅度 |
|------|:--------:|:--------:|:--------:|
| 数据库表 | 42 | ~22 | **-48%** |
| Controllers | 51 | ~25 | **-51%** |
| Models | 42 | ~22 | **-48%** |
| Views | 151 | ~70 | **-54%** |
| Services | 18 | ~8 | **-56%** |
| Routes 行数 | 249 | ~120 | **-52%** |
| Case Model | 804 行 | ~300 行 | **-63%** |

### 核心问题

1. **Case Model 过度膨胀**：804 行，包含财产保全、律师费、执行、上诉期、多委托人等大量边缘逻辑
2. **Analytics 过度建设**：4 个独立的数据分析控制器（case/contract/major_issue/lawyer_fee），目前用户量不支撑
3. **重复的 ZIP 导出逻辑**：在 cases_controller 和 contracts_controller 中各写了 100+ 行 ZIP 生成代码
4. **合同管理功能过重**：续签、日历、证据文件追加、合同风险分析 — 远超「合同审查+对账催收」的核心需求
5. **Team/权限系统过于复杂**：LawyerTeam、TeamAccessible、TeamAuthorizationConcern — 实际只有几个律师使用
6. **公告系统过度设计**：4 张表（announcements/read_statuses/dismissals/groups）+ 235 行控制器

---

## 二、目标架构（四板块）

```
┌──────────────────────────────────────────────────────┐
│                   律师工作平台                         │
├──────────────┬──────────────┬────────────┬───────────┤
│  合同管理     │  案件管理     │  重大事项   │  后台管理  │
│              │              │            │           │
│ • 合同审查    │ • 基本信息栏  │ • 上传资料  │ • 用户创建 │
│ • 对账与催收  │ • 开庭时间    │ • 描述问题  │ • 数据分析 │
│              │ • 保全续封    │            │ • 公告添加 │
│              │ • 上诉期满    │            │           │
├──────────────┴──────────────┴────────────┴───────────┤
│           用户角色：律师用户 / 企业用户                  │
└──────────────────────────────────────────────────────┘
```

---

## 三、具体优化操作清单

### Phase 1：删除/归档无用功能（预计 -40% 代码量）

#### 1.1 删除的控制器及对应视图

| 删除目标 | 文件 | 理由 |
|----------|------|------|
| 律师费分析 | `lawyer_fee_analytics_controller.rb` (431行) + views | 过度建设，合并到后台 dashboard 简版 |
| 合同分析 | `contract_analytics_controller.rb` (190行) + views | 过度建设，合并到后台 |
| 案件分析 | `case_analytics_controller.rb` (160行) + views | 过度建设，合并到后台 |
| 重大事项分析 | `major_issue_analytics_controller.rb` (126行) + views | 过度建设，合并到后台 |
| 合同风险 | `contract_risks_controller.rb` + views | 功能与合同审查重叠 |
| 案件团队协作 | `case_team_collaborations_controller.rb` + views | 团队系统过于复杂，简化 |
| 全局搜索 | `searches_controller.rb` + views | 当前数据量用不上全文检索 |
| 工作台 | `workbench_controller.rb` + views | 注释写了 backward compatibility |
| Todos | `todos_controller.rb` + views | 可合并到案件/重大事项 |
| 保存筛选 | `saved_filters_controller.rb` | 简化案件列表即可 |
| 案件筛选器 | `case_filters_controller.rb` | 简化 |

#### 1.2 删除的 Models

| 删除目标 | 理由 |
|----------|------|
| `CaseFilter` / `SavedFilter` | 简化筛选逻辑，不需要持久化 |
| `CaseNotification` | 用公告系统替代 |
| `CaseProgressEvent` | 用 WorkLog 替代 |
| `CaseQuestion` | 用重大事项讨论替代 |
| `CaseRelation` / `CaseSeries` / `CaseSeriesMembership` | 案件关联过度设计 |
| `CaseWeeklyReport` | 用工作日志汇总替代 |
| `SearchIndex` | 删除全文检索 |
| `AnnouncementGroup` / `AnnouncementDismissal` / `AnnouncementReadStatus` | 公告系统简化为单表 |
| `ContractTag` / `ContractTagging` | 合同标签过度设计 |
| `MajorIssueFollower` / `MajorIssueReadStatus` / `MajorIssueTodoItem` | 重大事项只需"上传资料+描述问题" |

#### 1.3 删除的 Services

| 删除目标 | 理由 |
|----------|------|
| `CaseAnalyticsService` | 合并到后台 |
| `ContractAnalyticsService` | 合并到后台 |
| `ContractRiskAnalyticService` | 合并到后台 |
| `LawyerFeeAnalyticsService` | 合并到后台 |
| `CaseStatisticsService` | 合并到后台 |
| `CaseNotificationService` | 简化 |
| `ExpiredPermissionCleanupService` | Team 系统简化后无需 |
| `MajorIssueProgressTrackerService` | 重大事项简化 |
| `UnifiedTodoService` | 删除 Todo 功能 |

#### 1.4 删除的数据库迁移涉及的表（新 schema 中不再创建）

```
drop: case_filters, saved_filters, case_notifications, case_progress_events,
      case_questions, case_relations, case_series, case_series_memberships,
      case_weekly_reports, search_indexes, announcement_groups,
      announcement_dismissals, announcement_read_statuses,
      contract_tags, contract_taggings,
      major_issue_followers, major_issue_read_statuses, major_issue_todo_items,
      friendly_id_slugs
```

**净删除：19 张表** → 剩余 ~23 张表（含 active_storage 3张 + good_job 4张 = 系统 7 张）

---

### Phase 2：Case Model 瘦身（804行 → ~300行）

#### 2.1 移除的功能块

| 功能块 | 行数 | 处理方式 |
|--------|:----:|----------|
| 执行阶段相关方法 | ~60行 | 删除（当案件到执行阶段时单独处理） |
| 多委托人方法 | ~30行 | 简化为单字段 |
| 第三人方法 | ~15行 | 简化为 JSON 字段即可 |
| 案件关联方法 | ~20行 | 删除 |
| CaseQuestion/CaseWeeklyReport 关联 | ~10行 | 删除 |
| 团队协作复杂方法 | ~80行 | 简化为主办律师+协办律师 |
| 企业用户权限判断 | ~50行 | 简化，企业用户只能看不能编辑 |
| 标的额/胜诉率计算 | ~40行 | 移到后台分析 |
| Searchable 实现 | ~20行 | 删除全文检索 |

#### 2.2 保留的核心字段（案件基本信息栏）

```ruby
# 核心字段
:name, :case_number, :case_type, :court_name, :status, :stage
:our_party_role, :counterparty_name, :our_party_name
:summary, :priority

# 重要时间（三个提醒）
:hearing_at                          # 开庭时间
:property_preservation_deadline      # 财产保全续封时间
:appeal_deadline_date                # 上诉期满（手动设置）
:judgement_received_at               # 领取判决书日期（用于自动计算上诉期）

# 律师团队（简化）
:lead_lawyer_id                      # 主办律师（直接字段，不走 join 表）
:assistant_lawyer_ids                # 协办律师（数组字段）

# 企业归属
:company_id

# 附件（精简）
has_many_attached :attachments       # 统一附件，不再分类
```

---

### Phase 3：合同管理精简（839行控制器 → ~250行）

#### 3.1 保留的核心功能

- **合同审查**：上传合同 → 律师标记已审查 → 添加审查意见（Comment）
- **对账与催收**：按月上传对账单（Reconciliation）→ 律师确认 → 催收记录

#### 3.2 删除的功能

| 功能 | 理由 |
|------|------|
| 合同日历视图 | 过度建设 |
| 一键续签 | 低频，手动创建即可 |
| 证据文件追加（6种分类） | 简化为统一附件 |
| 合同风险分析 | 删除独立模块 |
| 合同标签系统 | 简化 |
| 从合同快速创建案件 | 低频 |
| 合同详细信息（50+字段） | 精简到核心字段 |

#### 3.3 精简后的 Contract Model

```ruby
class Contract < ApplicationRecord
  belongs_to :company
  belongs_to :assigned_lawyer, class_name: 'LawyerAccount', optional: true
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :reconciliations, dependent: :destroy
  has_one_attached :file                    # 合同文件
  has_many_attached :supplement_files       # 补充材料

  validates :name, :signed_at, :end_at, :status, :file, :counterparty_name, presence: true
  validates :status, inclusion: { in: %w[active completed breach litigation] }

  scope :ordered, -> { order(created_at: :desc) }
  scope :pending_review, -> { where(reviewed_by_lawyer: false) }
  scope :expiring_soon, -> { where(status: 'active').where('end_at <= ?', 30.days.from_now) }
end
```

---

### Phase 4：重大事项极简化（549行控制器 → ~120行）

#### 你的需求定义：
> 只需要企业用户上传资料和简要描述要解决的问题

#### 4.1 精简后的 MajorIssue Model

```ruby
class MajorIssue < ApplicationRecord
  belongs_to :company
  has_many :comments, as: :commentable, dependent: :destroy
  has_many_attached :attachments

  validates :title, :description, presence: true
  validates :status, inclusion: { in: %w[pending resolved] }

  scope :ordered, -> { order(created_at: :desc) }
  scope :pending, -> { where(status: 'pending') }
end
```

#### 4.2 删除的功能

- 关注/取关机制（Followers）
- 阅读状态追踪（ReadStatuses）
- 待办任务（TodoItems）
- 状态机（AASM 5 个状态 → 2 个）
- 结论管理
- 分享链接
- 处理天数追踪
- 置顶评论/关键意见
- 团队成员分配
- 优先级系统（删除，默认都重要）

---

### Phase 5：后台管理精简

#### 5.1 保留

- 用户创建（律师账号 + 企业用户）
- 企业管理
- 公告添加（单表，简化）
- Dashboard（合并所有分析到一个简洁页面）

#### 5.2 删除

- 合同标签管理（`admin/contract_tags`）
- 操作日志独立页面（简化为 dashboard 最近操作）
- 管理员多账号管理（保留单个超级管理员即可）

---

### Phase 6：公告系统简化（4 表 → 1 表）

```ruby
# 当前：announcements + announcement_groups + announcement_read_statuses + announcement_dismissals
# 精简后：只保留 announcements 单表

class Announcement < ApplicationRecord
  belongs_to :company, optional: true   # nil = 全局公告
  validates :title, :content, presence: true
  scope :active, -> { where('expires_at IS NULL OR expires_at > ?', Time.current) }
end
```

---

### Phase 7：权限系统简化

#### 当前复杂度

- `TeamAccessible` concern
- `TeamAuthorizationConcern`
- `CompanyResolvable` concern
- `LawyerTeam` model（缺失）
- `BusinessTeamOwnership` model（缺失）
- `DataAccessLog` model（缺失）

#### 简化方案

只保留两层权限：
1. **律师用户**：可以看所有企业的数据，可以编辑
2. **企业用户**：只能看自己企业的数据，只能上传

```ruby
# application_controller.rb 中的简化权限
def require_lawyer!
  redirect_to login_path unless current_lawyer
end

def require_company_user!
  redirect_to login_path unless current_company_user
end

def current_company
  @current_company ||= if current_company_user
    current_company_user.company
  elsif current_lawyer && session[:viewing_company_id]
    Company.find_by(id: session[:viewing_company_id])
  end
end
```

删除所有 Team 相关的 concern 和逻辑。

---

## 四、精简后的目标路由

```ruby
Rails.application.routes.draw do
  root "home#index"

  # 认证
  resource :session, only: [:new, :create, :destroy]
  get "login", to: "sessions#new"

  # === 合同管理 ===
  resources :contracts do
    member do
      post :mark_as_reviewed
    end
    resources :reconciliations, only: [:create, :destroy] do
      member { post :mark_as_reviewed }
    end
    resources :comments, only: [:create]
  end

  # === 案件管理 ===
  resources :cases do
    resources :work_logs, only: [:index, :create, :update, :destroy]
    resources :comments, only: [:create]
  end

  # === 重大事项 ===
  resources :major_issues, only: [:index, :new, :create, :show, :update] do
    resources :comments, only: [:create]
    member { post :resolve }
  end

  # === 公告 ===
  resources :announcements, only: [:index]

  # === 律师选择企业 ===
  namespace :lawyer do
    resources :companies, only: [:index] do
      member { post :enter }
    end
    resource :profile, only: [:edit, :update]
  end

  # === 后台 ===
  namespace :admin do
    root "dashboard#index"
    resources :companies
    resources :lawyer_accounts
    resources :company_users
    resources :announcements
  end

  # 附件安全访问
  get "/secure/blobs/:signed_id/*filename", to: "secure_blobs#show", as: :secure_blob

  # 健康检查
  get "up", to: "rails/health#show"
end
```

---

## 五、执行计划与优先级

| 阶段 | 工作内容 | 预计耗时 | 风险 |
|:----:|----------|:--------:|:----:|
| **P0** | 创建 `archive/` 分支保存当前代码 | 5 min | 无 |
| **P1** | 删除 4 个 Analytics 控制器 + views + services | 1h | 低 |
| **P2** | 删除案件关联/筛选/搜索/团队协作等辅助功能 | 2h | 中 |
| **P3** | Case Model 瘦身 + 迁移删表 | 3h | 中 |
| **P4** | 合同管理精简（删日历/续签/风险/标签） | 2h | 低 |
| **P5** | 重大事项极简化（删关注/阅读/Todo） | 1h | 低 |
| **P6** | 公告系统 4 表→1 表 | 1h | 低 |
| **P7** | 权限系统简化（删 Team 相关） | 2h | 中 |
| **P8** | 路由清理 + 视图整理 + 测试 | 2h | 低 |

**总计预估：~14 小时（2-3 个工作日）**

---

## 六、注意事项

1. **先备份**：在执行任何删除前，创建 `git branch archive/full-features` 保存完整代码
2. **数据库迁移**：用 `db:migrate:down` 或写新迁移来 `drop_table`，不要直接删迁移文件
3. **渐进式删除**：每删一组功能后跑一次 `bin/rails routes` 和页面点击测试
4. **保留 Comment 模型**：它是三个板块（合同/案件/重大事项）共用的评论系统
5. **Active Storage 不动**：文件上传逻辑保持不变

---

## 七、是否需要我开始执行？

确认以下选项后我可以开始：

- [ ] **方案确认**：上述删除列表是否有你需要保留的功能？
- [ ] **执行方式**：是一次性大重构，还是分阶段逐步瘦身？
- [ ] **数据保留**：当前数据库中是否有生产数据需要迁移？（还是全新空库？）
