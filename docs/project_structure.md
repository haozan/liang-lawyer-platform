# 极光法律服务管理系统 - 项目结构说明

## 📦 项目概览

**项目名称**: 极光法律服务管理系统  
**技术栈**: Ruby on Rails 7.2 + PostgreSQL + Stimulus + Turbo  
**开发环境**: Ruby 3.1+ | Node.js 16+ | PostgreSQL 14+

---

## 📁 目录结构

```
极光法律服务管理系统/
├── app/                          # 应用核心代码
│   ├── controllers/              # 控制器层
│   │   ├── concerns/            # 共享模块
│   │   │   ├── team_authorization_concern.rb  # 团队权限控制
│   │   │   └── ...
│   │   ├── admin/               # 后台管理控制器
│   │   ├── cases_controller.rb  # 案件管理
│   │   ├── contracts_controller.rb  # 合同管理
│   │   ├── major_issues_controller.rb  # 重大事项
│   │   ├── case_analytics_controller.rb  # 案件数据分析
│   │   ├── contract_analytics_controller.rb  # 合同数据分析
│   │   ├── lawyer_fee_analytics_controller.rb  # 律师费分析
│   │   ├── todos_controller.rb  # 待办事项
│   │   ├── comments_controller.rb  # 评论系统
│   │   ├── reconciliations_controller.rb  # 对账单管理
│   │   └── ...
│   │
│   ├── models/                   # 数据模型层
│   │   ├── concerns/            # 模型共享模块
│   │   ├── lawyer_account.rb   # 律师账户模型
│   │   ├── company_user.rb     # 企业用户模型
│   │   ├── administrator.rb    # 管理员模型
│   │   ├── contract.rb         # 合同模型
│   │   ├── case.rb             # 案件模型
│   │   ├── major_issue.rb      # 重大事项模型
│   │   ├── comment.rb          # 评论模型
│   │   ├── reconciliation.rb   # 对账单模型
│   │   └── ...
│   │
│   ├── views/                    # 视图层
│   │   ├── layouts/             # 布局模板
│   │   │   └── application.html.erb
│   │   ├── shared/              # 共享组件
│   │   │   ├── _navbar.html.erb  # 导航栏
│   │   │   └── ...
│   │   ├── contracts/           # 合同视图
│   │   │   ├── index.html.erb
│   │   │   ├── show.html.erb
│   │   │   ├── new.html.erb
│   │   │   ├── sections/        # 合同详情各部分
│   │   │   └── ...
│   │   ├── cases/               # 案件视图
│   │   │   ├── index.html.erb
│   │   │   ├── show.html.erb
│   │   │   ├── sections/        # 案件详情各部分
│   │   │   └── ...
│   │   ├── major_issues/        # 重大事项视图
│   │   ├── case_analytics/      # 案件分析视图
│   │   ├── contract_analytics/  # 合同分析视图
│   │   ├── lawyer_fee_analytics/  # 律师费分析视图
│   │   └── ...
│   │
│   ├── javascript/               # 前端JavaScript
│   │   ├── controllers/         # Stimulus控制器
│   │   │   ├── clipboard_controller.ts  # 剪贴板
│   │   │   ├── dropdown_controller.ts   # 下拉菜单
│   │   │   ├── theme_controller.ts      # 主题切换
│   │   │   └── ...
│   │   └── application.js
│   │
│   ├── assets/                   # 静态资源
│   │   ├── stylesheets/
│   │   │   └── application.css  # 主样式文件（Tailwind）
│   │   └── images/
│   │
│   ├── services/                 # 业务服务层
│   │   ├── case_analytics_service.rb  # 案件分析服务
│   │   ├── contract_analytics_service.rb  # 合同分析服务
│   │   ├── lawyer_fee_analytics_service.rb  # 律师费分析服务
│   │   ├── unified_todo_service.rb  # 统一待办服务
│   │   ├── lawyer_todo_service.rb  # 律师待办服务
│   │   └── ...
│   │
│   ├── helpers/                  # 视图辅助方法
│   │   └── application_helper.rb
│   │
│   └── mailers/                  # 邮件发送
│
├── config/                       # 配置文件
│   ├── routes.rb                # 路由配置
│   ├── database.yml             # 数据库配置
│   ├── application.rb           # 应用配置
│   ├── application.yml          # 环境变量配置（Figaro）
│   ├── application.yml.example  # 环境变量示例
│   ├── appname.txt              # 应用名称
│   ├── environments/            # 环境配置
│   │   ├── development.rb
│   │   ├── test.rb
│   │   └── production.rb
│   ├── initializers/            # 初始化脚本
│   └── locales/                 # 国际化文件
│
├── db/                           # 数据库相关
│   ├── migrate/                 # 数据库迁移文件
│   ├── schema.rb                # 数据库结构
│   └── seeds.rb                 # 种子数据
│
├── lib/                          # 扩展库
│   ├── generators/              # 自定义生成器
│   │   ├── authentication/      # 认证系统生成器
│   │   ├── stripe_pay/          # 支付系统生成器
│   │   ├── llm/                 # LLM集成生成器
│   │   └── ...
│   └── tasks/                   # Rake任务
│
├── spec/                         # 测试文件
│   ├── requests/                # 请求测试
│   ├── models/                  # 模型测试
│   ├── services/                # 服务测试
│   ├── javascript/              # JavaScript测试（架构验证）
│   │   ├── stimulus_validation_spec.rb
│   │   ├── turbo_architecture_validation_spec.rb
│   │   └── project_conventions_validation_spec.rb
│   └── spec_helper.rb
│
├── public/                       # 公共文件
│   ├── favicon.ico
│   └── robots.txt
│
├── docs/                         # 项目文档
│   ├── user_manual.md           # 用户使用说明（Markdown）
│   ├── user_manual.doc          # 用户使用说明（Word）
│   ├── project.md               # 项目说明文档
│   └── project_structure.md     # 项目结构说明（本文件）
│
├── bin/                          # 可执行脚本
│   ├── dev                      # 启动开发服务器
│   ├── rails                    # Rails命令
│   └── setup                    # 项目初始化
│
├── .clackyrules                  # 项目开发规范
├── .rspec                        # RSpec配置
├── .gitignore                    # Git忽略文件
├── Gemfile                       # Ruby依赖
├── Gemfile.lock                  # Ruby依赖锁定
├── package.json                  # Node.js依赖
├── package-lock.json             # Node.js依赖锁定
├── tailwind.config.js            # Tailwind配置
├── Rakefile                      # Rake任务配置
└── README.md                     # 项目说明
```

---

## 🏗️ 核心架构

### 1. 用户系统架构

系统采用**多用户类型**设计，三类用户独立管理：

```
用户体系
├── LawyerAccount (律师用户)
│   ├── assistant (律师助理)
│   ├── lawyer (律师)
│   ├── senior_lawyer (资深律师)
│   ├── team_leader (团队负责人)
│   └── super_admin (超级管理员)
│
├── CompanyUser (企业用户)
│   ├── employee (员工)
│   ├── executive (高管)
│   └── boss (企业主)
│
└── Administrator (系统管理员)
    ├── admin (管理员)
    └── super_admin (超级管理员)
```

### 2. 核心业务模块

#### 合同管理模块
- **模型**: `Contract`, `Reconciliation`
- **控制器**: `ContractsController`, `ReconciliationsController`
- **核心功能**:
  - 合同创建（快速模式/完整模式）
  - 律师审查流程
  - 履约跟踪
  - 对账单管理
  - 风险标记
  - 日历视图
  - 归档导出

#### 案件管理模块
- **模型**: `Case`, `CaseTeamMember`, `WorkLog`
- **控制器**: `CasesController`
- **核心功能**:
  - 案件创建与跟踪
  - 团队协作（主办律师、协办律师）
  - 审理阶段管理
  - 材料分类归档
  - 财产保全跟踪
  - 律师费管理
  - 工作日志

#### 重大事项研讨模块
- **模型**: `MajorIssue`
- **控制器**: `MajorIssuesController`
- **核心功能**:
  - 问题建档
  - @律师提问
  - 讨论记录
  - 状态流转（待答复→讨论中→已解决→已归档）
  - 关注功能

#### 数据分析模块
- **服务类**: `CaseAnalyticsService`, `ContractAnalyticsService`, `LawyerFeeAnalyticsService`
- **控制器**: `CaseAnalyticsController`, `ContractAnalyticsController`, `LawyerFeeAnalyticsController`
- **核心功能**:
  - 多维度数据看板
  - 趋势分析图表
  - 风险预警
  - 团队工作量统计
  - 数据导出（CSV）

### 3. 公共服务

#### 评论系统
- **模型**: `Comment`
- **控制器**: `CommentsController`
- **特性**:
  - 多态关联（支持合同、案件、重大事项评论）
  - @提及功能
  - 可见性控制（公开/仅律师可见）
  - 附件支持

#### 待办系统
- **服务类**: `UnifiedTodoService`, `LawyerTodoService`
- **控制器**: `TodosController`
- **特性**:
  - 统一待办汇总
  - 分类展示（企业用户/律师用户）
  - 智能提醒

#### 文件管理
- **技术**: ActiveStorage
- **控制器**: `SecureBlobsController`
- **特性**:
  - 安全下载（权限控制）
  - 批量归档导出
  - 文件预览

---

## 🛠️ 技术栈详解

### 后端技术

| 技术 | 版本 | 用途 |
|------|------|------|
| Ruby on Rails | 7.2 | Web应用框架 |
| PostgreSQL | 14+ | 关系型数据库 |
| Figaro | - | 环境变量管理 |
| Kaminari | - | 分页 |
| FriendlyId | - | 友好URL |
| Active Storage | - | 文件上传 |
| Puma | - | Web服务器 |

### 前端技术

| 技术 | 版本 | 用途 |
|------|------|------|
| Stimulus | 3.x | JavaScript框架 |
| Turbo | 7.x | 页面导航增强 |
| Tailwind CSS | 3.x | CSS框架 |
| TypeScript | 4.x | 类型安全 |
| esbuild | - | JavaScript打包 |

### 测试技术

| 技术 | 用途 |
|------|------|
| RSpec | 单元测试、请求测试 |
| 自定义验证器 | 架构规范验证 |

---

## 🚀 快速开始

### 1. 环境要求

```bash
Ruby 3.1+
Node.js 16+
PostgreSQL 14+
```

### 2. 安装依赖

```bash
# 安装Ruby依赖
bundle install

# 安装Node.js依赖
npm install

# 配置环境变量
cp config/application.yml.example config/application.yml
# 编辑 config/application.yml，配置数据库等信息
```

### 3. 数据库初始化

```bash
# 创建数据库
rails db:create

# 运行迁移
rails db:migrate

# 加载种子数据
rails db:seed
```

### 4. 启动服务

```bash
# 启动开发服务器（包含Rails服务器 + CSS/JS编译）
bin/dev
```

访问: `http://localhost:3000`

### 5. 运行测试

```bash
# 运行所有测试
rake test

# 或单独运行RSpec
bundle exec rspec
```

---

## 📝 开发规范

### 代码规范

详见项目根目录的 `.clackyrules` 文件，核心规范：

1. **启动命令**: 使用 `bin/dev`（不要用 `rails s`）
2. **模型创建**: 优先使用 `rails generate models` 批量生成
3. **前端架构**: 
   - 使用Stimulus控制器（不用jQuery）
   - 使用Turbo Stream响应（不用JSON API）
   - 禁止内联JavaScript
4. **样式规范**: 
   - 使用Tailwind CSS
   - 使用设计系统变量（application.css）
   - 禁止直接使用颜色值
5. **测试规范**: 
   - 交付前必须运行 `rake test`
   - 确保所有测试通过

### Git工作流

```bash
# 创建功能分支
git checkout -b feature/your-feature-name

# 提交代码
git add .
git commit -m "描述你的更改"

# 推送到远程
git push origin feature/your-feature-name
```

---

## 📊 数据库设计

### 核心表结构

#### 用户相关
- `lawyer_accounts` - 律师账户
- `company_users` - 企业用户
- `administrators` - 管理员
- `companies` - 企业信息

#### 业务核心
- `contracts` - 合同
- `reconciliations` - 对账单
- `cases` - 案件
- `case_team_members` - 案件团队成员
- `work_logs` - 工作日志
- `major_issues` - 重大事项

#### 公共功能
- `comments` - 评论（多态）
- `active_storage_blobs` - 文件存储
- `active_storage_attachments` - 文件关联
- `announcements` - 公告

---

## 🔐 权限系统

### 权限控制策略

1. **团队权限**: 通过 `TeamAuthorizationConcern` 实现
2. **角色权限**: 基于用户角色（role字段）判断
3. **操作权限**: 控制器层验证（before_action）

### 权限检查示例

```ruby
# 检查是否是律师
def require_lawyer!
  redirect_to root_path unless current_user.is_a?(LawyerAccount) && current_user.lawyer?
end

# 检查团队访问权限
def check_team_access
  @company = Company.find(params[:company_id])
  unless current_lawyer.can_access_company?(@company)
    redirect_to root_path, alert: "无权访问"
  end
end

# 检查企业主权限
def require_boss!
  redirect_to root_path unless current_company_user.boss?
end
```

---

## 📦 部署说明

### 生产环境配置

1. **环境变量配置** (`config/application.yml`)
```yaml
production:
  DATABASE_URL: "postgresql://..."
  SECRET_KEY_BASE: "..."
  RAILS_ENV: production
```

2. **资产预编译**
```bash
RAILS_ENV=production rails assets:precompile
```

3. **数据库迁移**
```bash
RAILS_ENV=production rails db:migrate
```

### 推荐部署平台

- Railway
- Heroku
- AWS
- 阿里云
- 腾讯云

---

## 📚 相关文档

- [用户使用说明](./user_manual.md) - 面向最终用户的完整使用指南
- [项目说明](./project.md) - 项目背景和需求说明
- [开发规范](./.clackyrules) - 开发规范和最佳实践

---

## 🆘 技术支持

- **系统使用问题**: 联系律师团队或系统管理员
- **技术开发问题**: 查看项目文档和代码注释
- **Bug报告**: 通过系统内"帮助与反馈"功能提交

---

**文档版本**: v1.0  
**更新日期**: 2026年3月  
**维护团队**: 极光法律服务管理系统开发团队
