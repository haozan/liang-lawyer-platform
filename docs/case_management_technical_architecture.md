# 案件管理板块全面优化 - 技术架构方案

## 🎯 项目目标
一次性彻底解决案件管理板块所有用户体验痛点,避免后续重复修改。

## 📊 数据库设计

### 新增表结构

#### 1. `case_filters` - 保存的筛选条件
```ruby
create_table :case_filters do |t|
  t.references :user, polymorphic: true, null: false
  t.string :name, null: false                    # 筛选条件名称
  t.jsonb :filter_params, default: {}            # 筛选参数
  t.boolean :is_default, default: false          # 是否默认
  t.integer :position, default: 0                # 排序
  t.timestamps
end
```

#### 2. `case_work_log_templates` - 工作记录模板
```ruby
create_table :case_work_log_templates do |t|
  t.string :name, null: false                    # 模板名称
  t.string :category, null: false                # 模板分类
  t.text :title_template                         # 标题模板
  t.text :content_template                       # 内容模板
  t.boolean :is_system, default: false           # 系统模板
  t.references :lawyer_account                   # 创建者
  t.timestamps
end
```

#### 3. `case_notifications` - 案件通知记录
```ruby
create_table :case_notifications do |t|
  t.references :case, null: false
  t.references :recipient, polymorphic: true, null: false
  t.string :notification_type, null: false       # 通知类型
  t.string :title                                # 通知标题
  t.text :content                                # 通知内容
  t.jsonb :metadata, default: {}                 # 元数据
  t.datetime :read_at                            # 已读时间
  t.datetime :sent_at                            # 发送时间
  t.boolean :email_sent, default: false          # 邮件已发送
  t.boolean :sms_sent, default: false            # 短信已发送
  t.timestamps
end
```

#### 4. `case_relations` - 案件关联关系
```ruby
create_table :case_relations do |t|
  t.bigint :from_case_id, null: false
  t.bigint :to_case_id, null: false
  t.string :relation_type, null: false           # 关系类型: parent/child/related/series
  t.text :description                            # 关系描述
  t.timestamps
end
add_index :case_relations, [:from_case_id, :to_case_id], unique: true
```

#### 5. `case_series` - 系列案件
```ruby
create_table :case_series do |t|
  t.string :name, null: false                    # 系列名称
  t.text :description                            # 系列描述
  t.references :company, null: false
  t.references :created_by, polymorphic: true
  t.timestamps
end

create_table :case_series_memberships do |t|
  t.references :case_series, null: false
  t.references :case, null: false
  t.integer :position, default: 0
  t.timestamps
end
```

#### 6. `case_questions` - 案件问答系统
```ruby
create_table :case_questions do |t|
  t.references :case, null: false
  t.references :asker, polymorphic: true, null: false    # 提问者
  t.text :question, null: false
  t.text :answer                                         # 回答
  t.references :answerer, polymorphic: true              # 回答者
  t.datetime :answered_at                                # 回答时间
  t.boolean :is_resolved, default: false                 # 已解决
  t.timestamps
end
```

#### 7. `case_progress_events` - 案件进度事件（自动生成）
```ruby
create_table :case_progress_events do |t|
  t.references :case, null: false
  t.string :event_type, null: false              # 事件类型
  t.string :title, null: false                   # 事件标题
  t.text :description                            # 事件描述
  t.date :event_date, null: false                # 事件日期
  t.datetime :event_time                         # 事件时间
  t.jsonb :metadata, default: {}                 # 元数据
  t.boolean :is_milestone, default: false        # 是否里程碑
  t.boolean :is_automated, default: false        # 是否自动生成
  t.timestamps
end
```

#### 8. `case_weekly_reports` - 案件周报（自动生成）
```ruby
create_table :case_weekly_reports do |t|
  t.references :case, null: false
  t.date :week_start_date, null: false
  t.date :week_end_date, null: false
  t.jsonb :work_summary, default: {}             # 本周工作摘要
  t.jsonb :next_week_plan, default: {}           # 下周计划
  t.text :lawyer_assessment                      # 律师评估
  t.datetime :generated_at                       # 生成时间
  t.boolean :is_auto_generated, default: true    # 自动生成
  t.timestamps
end
```

### 修改现有表

#### 修改 `work_logs` 表
```ruby
add_column :work_logs, :log_type, :string, default: 'general'  # 类型
add_column :work_logs, :is_todo, :boolean, default: false       # 是否待办
add_column :work_logs, :todo_status, :string                    # 待办状态
add_column :work_logs, :due_date, :date                         # 截止日期
add_column :work_logs, :reminder_at, :datetime                  # 提醒时间
add_column :work_logs, :completed_at, :datetime                 # 完成时间
add_column :work_logs, :is_important, :boolean, default: false  # 是否重要
add_column :work_logs, :assigned_to_id, :integer                # 负责人
add_column :work_logs, :assigned_to_type, :string               # 负责人类型

add_index :work_logs, :log_type
add_index :work_logs, :is_todo
add_index :work_logs, :due_date
```

#### 修改 `cases` 表
```ruby
add_column :cases, :priority, :string, default: 'normal'        # 优先级
add_column :cases, :estimated_end_date, :date                   # 预计结案日期
add_column :cases, :tags, :string, array: true, default: []     # 标签
add_column :cases, :last_activity_at, :datetime                 # 最后活动时间
add_column :cases, :series_id, :integer                         # 所属系列

add_index :cases, :priority
add_index :cases, :tags, using: :gin
add_index :cases, :last_activity_at
```

---

## 🏗️ 核心功能实现

### 方案一：智能筛选搜索系统

#### 1.1 Model层 - 筛选逻辑

**`app/models/concerns/case_filterable.rb`**
```ruby
module CaseFilterable
  extend ActiveSupport::Concern
  
  included do
    # 高级筛选
    scope :filter_by_status, ->(statuses) { 
      where(status: statuses) if statuses.present? 
    }
    
    scope :filter_by_stage, ->(stages) { 
      where(stage: stages) if stages.present? 
    }
    
    scope :filter_by_case_type, ->(types) { 
      where(case_type: types) if types.present? 
    }
    
    scope :filter_by_priority, ->(priorities) { 
      where(priority: priorities) if priorities.present? 
    }
    
    scope :filter_by_company, ->(company_id) { 
      where(company_id: company_id) if company_id.present? 
    }
    
    scope :filter_by_team_member, ->(lawyer_id) {
      joins(:case_team_members).where(case_team_members: { lawyer_account_id: lawyer_id }).distinct if lawyer_id.present?
    }
    
    scope :filter_by_lead_lawyer, ->(lawyer_id) {
      joins(:case_team_members).where(case_team_members: { lawyer_account_id: lawyer_id, role: 'lead_lawyer' }).distinct if lawyer_id.present?
    }
    
    scope :filter_by_date_range, ->(field, start_date, end_date) {
      where("#{field} BETWEEN ? AND ?", start_date, end_date) if start_date.present? && end_date.present?
    }
    
    scope :upcoming_hearings, ->(days) {
      where('hearing_at BETWEEN ? AND ?', Time.current, days.days.from_now) if days.present?
    }
    
    scope :appeal_deadline_approaching, ->(days) {
      where('appeal_deadline_date BETWEEN ? AND ?', Date.today, days.days.from_now) if days.present?
    }
    
    # 全文搜索
    scope :search_by_keyword, ->(keyword) {
      return all if keyword.blank?
      
      where(
        "name ILIKE :keyword OR case_number ILIKE :keyword OR court_name ILIKE :keyword OR summary ILIKE :keyword",
        keyword: "%#{keyword}%"
      )
    }
    
    # 智能排序
    scope :order_by_field, ->(field, direction = 'desc') {
      direction = direction.to_s.downcase == 'asc' ? 'asc' : 'desc'
      case field.to_s
      when 'updated_at', 'last_activity'
        order(last_activity_at: direction, updated_at: direction)
      when 'filing_at', 'filing_date'
        order(filing_at: direction)
      when 'hearing_at', 'hearing_date'
        order(Arel.sql("hearing_at #{direction} NULLS LAST"))
      when 'priority'
        order(Arel.sql("CASE priority WHEN 'urgent' THEN 1 WHEN 'high' THEN 2 WHEN 'normal' THEN 3 WHEN 'low' THEN 4 END #{direction}"))
      when 'name'
        order(name: direction)
      else
        order(filing_at: direction)
      end
    }
  end
  
  class_methods do
    def apply_filters(params)
      scope = all
      
      scope = scope.filter_by_status(params[:statuses]) if params[:statuses].present?
      scope = scope.filter_by_stage(params[:stages]) if params[:stages].present?
      scope = scope.filter_by_case_type(params[:case_types]) if params[:case_types].present?
      scope = scope.filter_by_priority(params[:priorities]) if params[:priorities].present?
      scope = scope.filter_by_company(params[:company_id]) if params[:company_id].present?
      scope = scope.filter_by_team_member(params[:team_member_id]) if params[:team_member_id].present?
      scope = scope.filter_by_lead_lawyer(params[:lead_lawyer_id]) if params[:lead_lawyer_id].present?
      scope = scope.upcoming_hearings(params[:hearing_days]) if params[:hearing_days].present?
      scope = scope.appeal_deadline_approaching(params[:appeal_days]) if params[:appeal_days].present?
      scope = scope.search_by_keyword(params[:keyword]) if params[:keyword].present?
      
      # 日期范围筛选
      if params[:filed_from].present? && params[:filed_to].present?
        scope = scope.filter_by_date_range(:filing_at, params[:filed_from], params[:filed_to])
      end
      
      # 排序
      scope = scope.order_by_field(params[:sort_by] || 'updated_at', params[:sort_direction] || 'desc')
      
      scope
    end
  end
end
```

#### 1.2 Controller层 - 筛选应用

**更新 `app/controllers/cases_controller.rb`**
```ruby
def index
  @filter_params = filter_params
  
  # 加载保存的筛选条件
  @saved_filters = current_user_or_lawyer&.case_filters&.order(:position)
  
  # 应用筛选
  base_scope = if @company
    @company.cases.not_deleted
  else
    Case.not_deleted
  end
  
  @cases = base_scope.apply_filters(@filter_params).page(params[:page]).per(20)
  
  # 统计数据
  @stats = calculate_stats(base_scope)
  
  # 快速筛选选项
  @filter_options = {
    companies: Company.ordered.pluck(:name, :id),
    team_members: LawyerAccount.ordered.pluck(:name, :id),
    statuses: Case.distinct.pluck(:status).compact,
    stages: Case.distinct.pluck(:stage).compact,
    case_types: Case.distinct.pluck(:case_type).compact
  }
end

private

def filter_params
  params.permit(
    :keyword, :company_id, :team_member_id, :lead_lawyer_id,
    :sort_by, :sort_direction, :hearing_days, :appeal_days,
    :filed_from, :filed_to,
    statuses: [], stages: [], case_types: [], priorities: []
  )
end

def calculate_stats(scope)
  {
    total: scope.count,
    pending: scope.where(status: 'pending').count,
    investigating: scope.where(status: 'investigating').count,
    in_court: scope.where(status: 'in_court').count,
    closed: scope.where(status: 'closed').count,
    urgent_hearings: scope.where('hearing_at BETWEEN ? AND ?', Time.current, 7.days.from_now).count,
    appeal_deadlines: scope.where('appeal_deadline_date BETWEEN ? AND ?', Date.today, 10.days.from_now).count
  }
end
```

#### 1.3 View层 - 筛选界面

**创建 `app/views/cases/_filter_panel.html.erb`**
（完整筛选面板UI,支持折叠/展开）

---

### 方案二：团队协作增强

#### 2.1 案件列表显示团队信息

**修改 `app/views/cases/index.html.erb`**
在案件卡片中显示团队成员信息

#### 2.2 我的案件视图

**新增路由**
```ruby
resources :cases do
  collection do
    get :my_cases
    get :my_lead_cases
    get :team_workload
  end
end
```

**Controller方法**
```ruby
def my_cases
  @cases = Case.not_deleted
    .filter_by_team_member(current_lawyer.id)
    .page(params[:page])
end

def my_lead_cases
  @cases = Case.not_deleted
    .filter_by_lead_lawyer(current_lawyer.id)
    .page(params[:page])
end

def team_workload
  @workload_stats = LawyerAccount.all.map do |lawyer|
    {
      lawyer: lawyer,
      total_cases: Case.filter_by_team_member(lawyer.id).count,
      lead_cases: Case.filter_by_lead_lawyer(lawyer.id).count,
      active_cases: Case.filter_by_team_member(lawyer.id).where(status: ['investigating', 'in_court']).count
    }
  end
end
```

---

### 方案三：结构化工作大事记

#### 3.1 工作记录类型定义

**`app/models/work_log.rb` 添加**
```ruby
WORK_LOG_TYPES = {
  'communication' => { name: '沟通记录', icon: 'phone', color: 'blue' },
  'investigation' => { name: '调查取证', icon: 'search', color: 'green' },
  'document' => { name: '文书准备', icon: 'file-text', color: 'purple' },
  'trial_prep' => { name: '庭审准备', icon: 'briefcase', color: 'orange' },
  'trial' => { name: '庭审记录', icon: 'scales', color: 'red' },
  'submission' => { name: '材料提交', icon: 'upload', color: 'indigo' },
  'todo' => { name: '待办事项', icon: 'check-square', color: 'yellow' },
  'general' => { name: '其他记录', icon: 'edit', color: 'gray' }
}.freeze

TODO_STATUSES = %w[pending in_progress completed cancelled].freeze
```

#### 3.2 待办事项模式

**表单增强**
```erb
<%= f.select :log_type, 
  options_for_select(WorkLog::WORK_LOG_TYPES.map { |k, v| [v[:name], k] }), 
  {}, 
  class: "form-select" 
%>

<% if log_type == 'todo' %>
  <%= f.date_field :due_date, class: "form-input" %>
  <%= f.datetime_field :reminder_at, class: "form-input" %>
  <%= f.select :assigned_to_id, lawyer_options, {}, class: "form-select" %>
<% end %>
```

#### 3.3 提醒Job

**`app/jobs/work_log_reminder_job.rb`**
```ruby
class WorkLogReminderJob < ApplicationJob
  queue_as :default
  
  def perform
    # 查找需要提醒的待办事项
    WorkLog.where(is_todo: true, todo_status: ['pending', 'in_progress'])
           .where('reminder_at <= ? AND reminder_at > ?', Time.current, 1.hour.ago)
           .find_each do |work_log|
      send_reminder(work_log)
    end
  end
  
  private
  
  def send_reminder(work_log)
    CaseNotification.create!(
      case: work_log.case,
      recipient: work_log.assigned_to || work_log.submitter,
      notification_type: 'work_log_reminder',
      title: "待办事项提醒：#{work_log.title}",
      content: "案件《#{work_log.case.name}》的待办事项即将到期",
      metadata: { work_log_id: work_log.id }
    )
  end
end
```

**配置定时任务 `config/recurring.yml`**
```yaml
work_log_reminder:
  cron: "*/15 * * * *"  # 每15分钟检查一次
  class: "WorkLogReminderJob"
```

---

### 方案四：进度可视化系统

#### 4.1 进度事件自动生成

**`app/models/concerns/case_progress_trackable.rb`**
```ruby
module CaseProgressTrackable
  extend ActiveSupport::Concern
  
  included do
    after_update :track_progress_changes
    after_create :create_initial_progress_event
  end
  
  private
  
  def track_progress_changes
    track_status_change if saved_change_to_status?
    track_stage_change if saved_change_to_stage?
    track_filing if saved_change_to_filing_at?
    track_hearing if saved_change_to_hearing_at?
    track_judgement if saved_change_to_judgement_received_at?
    track_archive if saved_change_to_archived_at?
  end
  
  def create_initial_progress_event
    CaseProgressEvent.create!(
      case: self,
      event_type: 'case_created',
      title: '案件创建',
      description: "案件《#{name}》已创建",
      event_date: created_at.to_date,
      event_time: created_at,
      is_milestone: true,
      is_automated: true
    )
  end
  
  def track_status_change
    CaseProgressEvent.create!(
      case: self,
      event_type: 'status_changed',
      title: "状态变更：#{status_display}",
      description: "案件状态从「#{saved_changes['status'][0]}」变更为「#{status}」",
      event_date: Date.today,
      event_time: Time.current,
      is_milestone: true,
      is_automated: true
    )
  end
  
  # ... 其他跟踪方法类似
end
```

#### 4.2 周报自动生成

**`app/services/case_weekly_report_generator.rb`**
```ruby
class CaseWeeklyReportGenerator < ApplicationService
  def initialize(case_record)
    @case = case_record
    @week_start = Date.today.beginning_of_week
    @week_end = Date.today.end_of_week
  end
  
  def call
    generate_report
  end
  
  private
  
  def generate_report
    CaseWeeklyReport.create!(
      case: @case,
      week_start_date: @week_start,
      week_end_date: @week_end,
      work_summary: collect_work_summary,
      next_week_plan: generate_next_week_plan,
      lawyer_assessment: generate_assessment,
      generated_at: Time.current
    )
  end
  
  def collect_work_summary
    {
      work_logs_count: @case.work_logs.where(date: @week_start..@week_end).count,
      new_attachments_count: count_new_attachments,
      communications_count: @case.work_logs.where(log_type: 'communication', date: @week_start..@week_end).count,
      events: @case.case_progress_events.where(event_date: @week_start..@week_end).pluck(:title)
    }
  end
  
  def generate_next_week_plan
    {
      pending_todos: @case.work_logs.where(is_todo: true, todo_status: ['pending', 'in_progress']).pluck(:title),
      upcoming_hearing: @case.hearing_at.present? && @case.hearing_at.between?(Time.current, 1.week.from_now)
    }
  end
  
  def generate_assessment
    if @case.status == 'closed'
      "案件已结案"
    elsif @case.work_logs.where(date: @week_start..@week_end).count > 0
      "案件进展顺利，本周已完成多项工作"
    else
      "本周暂无进展记录"
    end
  end
  
  def count_new_attachments
    # 统计本周新增附件数量（通过ActiveStorage）
    0  # 简化实现
  end
end
```

**定时任务**
```yaml
weekly_report_generation:
  cron: "0 18 * * 5"  # 每周五下午6点生成
  class: "GenerateWeeklyReportsJob"
```

---

### 方案五：智能提醒通知系统

#### 5.1 通知中心Service

**`app/services/case_notification_service.rb`**
```ruby
class CaseNotificationService < ApplicationService
  def initialize(case_record, notification_type, recipients, options = {})
    @case = case_record
    @notification_type = notification_type
    @recipients = Array(recipients)
    @options = options
  end
  
  def call
    @recipients.each do |recipient|
      create_notification(recipient)
      send_notification_channels(recipient)
    end
  end
  
  private
  
  def create_notification(recipient)
    CaseNotification.create!(
      case: @case,
      recipient: recipient,
      notification_type: @notification_type,
      title: notification_title,
      content: notification_content,
      metadata: @options[:metadata] || {},
      sent_at: Time.current
    )
  end
  
  def send_notification_channels(recipient)
    # 站内消息（已创建CaseNotification记录）
    
    # 邮件通知
    if should_send_email?(recipient)
      CaseNotificationMailer.notify(recipient, @case, @notification_type).deliver_later
    end
    
    # 短信通知（关键事项）
    if should_send_sms?(recipient)
      # SMS发送逻辑
    end
  end
  
  def notification_title
    case @notification_type
    when 'hearing_reminder'
      "开庭提醒：#{@case.name}"
    when 'appeal_deadline_reminder'
      "上诉期限提醒：#{@case.name}"
    when 'status_changed'
      "案件状态变更：#{@case.name}"
    when 'team_member_added'
      "您已加入案件团队：#{@case.name}"
    when 'new_work_log'
      "案件新增工作记录：#{@case.name}"
    when 'new_comment'
      "案件新增评论：#{@case.name}"
    else
      "案件通知：#{@case.name}"
    end
  end
  
  def notification_content
    @options[:content] || "案件《#{@case.name}》有新的动态"
  end
  
  def should_send_email?(recipient)
    # 检查用户偏好设置
    return false unless recipient.respond_to?(:notification_preferences)
    recipient.notification_preferences[:email] != false
  end
  
  def should_send_sms?(recipient)
    # 只有紧急提醒发送短信
    ['hearing_reminder', 'appeal_deadline_reminder'].include?(@notification_type)
  end
end
```

#### 5.2 定时提醒Job

**`app/jobs/case_reminder_job.rb`**
```ruby
class CaseReminderJob < ApplicationJob
  queue_as :default
  
  def perform
    send_hearing_reminders
    send_appeal_deadline_reminders
    send_work_log_reminders
  end
  
  private
  
  def send_hearing_reminders
    # 7天前、3天前、1天前、当天提醒
    [7, 3, 1, 0].each do |days_before|
      target_date = days_before.days.from_now.beginning_of_day
      
      Case.where('DATE(hearing_at) = ?', target_date.to_date).find_each do |case_record|
        next if already_reminded?(case_record, 'hearing_reminder', days_before)
        
        recipients = collect_case_team(case_record) + collect_company_users(case_record)
        
        CaseNotificationService.call(
          case_record,
          'hearing_reminder',
          recipients,
          content: "案件将在#{days_before == 0 ? '今天' : "#{days_before}天后"}开庭",
          metadata: { days_before: days_before }
        )
        
        mark_as_reminded(case_record, 'hearing_reminder', days_before)
      end
    end
  end
  
  def send_appeal_deadline_reminders
    # 10天前、5天前、最后1天提醒
    [10, 5, 1].each do |days_before|
      target_date = days_before.days.from_now.to_date
      
      Case.where(appeal_deadline_date: target_date).find_each do |case_record|
        next if already_reminded?(case_record, 'appeal_deadline_reminder', days_before)
        
        recipients = collect_case_team(case_record)
        
        CaseNotificationService.call(
          case_record,
          'appeal_deadline_reminder',
          recipients,
          content: "上诉期限还剩#{days_before}天",
          metadata: { days_before: days_before }
        )
        
        mark_as_reminded(case_record, 'appeal_deadline_reminder', days_before)
      end
    end
  end
  
  def send_work_log_reminders
    WorkLog.where(is_todo: true, todo_status: ['pending', 'in_progress'])
           .where('due_date <= ?', 3.days.from_now)
           .where('due_date >= ?', Date.today)
           .find_each do |work_log|
      next if work_log.reminder_at.present? && work_log.reminder_at < 1.day.ago
      
      recipient = work_log.assigned_to || work_log.submitter
      
      CaseNotificationService.call(
        work_log.case,
        'work_log_reminder',
        recipient,
        content: "待办事项《#{work_log.title}》将在#{(work_log.due_date - Date.today).to_i}天后到期"
      )
      
      work_log.update(reminder_at: Time.current)
    end
  end
  
  def collect_case_team(case_record)
    case_record.team_lawyers.to_a
  end
  
  def collect_company_users(case_record)
    case_record.company.company_users.to_a
  end
  
  def already_reminded?(case_record, reminder_type, days_before)
    CaseNotification.exists?(
      case: case_record,
      notification_type: reminder_type,
      metadata: { days_before: days_before }
    )
  end
  
  def mark_as_reminded(case_record, reminder_type, days_before)
    # 已通过CaseNotificationService创建记录
  end
end
```

#### 5.3 通知中心页面

**路由**
```ruby
resources :case_notifications, only: [:index] do
  member do
    post :mark_as_read
  end
  collection do
    post :mark_all_as_read
  end
end
```

**Controller**
```ruby
class CaseNotificationsController < ApplicationController
  before_action :require_authentication
  
  def index
    @notifications = current_user_or_lawyer.case_notifications
                                            .order(created_at: :desc)
                                            .page(params[:page])
    
    @unread_count = current_user_or_lawyer.case_notifications.where(read_at: nil).count
  end
  
  def mark_as_read
    @notification = CaseNotification.find(params[:id])
    @notification.update(read_at: Time.current)
    redirect_to @notification.case
  end
  
  def mark_all_as_read
    current_user_or_lawyer.case_notifications.where(read_at: nil).update_all(read_at: Time.current)
    redirect_to case_notifications_path
  end
end
```

---

### 方案六：批量操作工具

#### 6.1 批量操作Controller

**`app/controllers/cases/bulk_operations_controller.rb`**
```ruby
class Cases::BulkOperationsController < ApplicationController
  before_action :require_lawyer_authentication
  
  def update_status
    case_ids = params[:case_ids]
    new_status = params[:status]
    
    cases = Case.where(id: case_ids)
    cases.update_all(status: new_status, updated_at: Time.current)
    
    redirect_to cases_path, notice: "已批量更新#{cases.count}个案件的状态"
  end
  
  def add_team_member
    case_ids = params[:case_ids]
    lawyer_id = params[:lawyer_account_id]
    role = params[:role]
    
    cases = Case.where(id: case_ids)
    success_count = 0
    
    cases.each do |case_record|
      next if case_record.case_team_members.exists?(lawyer_account_id: lawyer_id)
      
      case_record.case_team_members.create!(
        lawyer_account_id: lawyer_id,
        role: role
      )
      success_count += 1
    end
    
    redirect_to cases_path, notice: "已为#{success_count}个案件添加团队成员"
  end
  
  def export_archives
    case_ids = params[:case_ids]
    cases = Case.where(id: case_ids)
    
    # 生成批量档案压缩包
    zip_data = Cases::BulkArchiveExporter.call(cases)
    
    send_data zip_data, 
              filename: "案件档案批量导出_#{Date.today}.zip", 
              type: 'application/zip'
  end
  
  def archive
    case_ids = params[:case_ids]
    cases = Case.where(id: case_ids)
    
    cases.update_all(
      archived_at: Date.today,
      status: 'closed',
      updated_at: Time.current
    )
    
    redirect_to cases_path, notice: "已批量归档#{cases.count}个案件"
  end
end
```

**路由**
```ruby
namespace :cases do
  post 'bulk/update_status', to: 'bulk_operations#update_status'
  post 'bulk/add_team_member', to: 'bulk_operations#add_team_member'
  post 'bulk/export_archives', to: 'bulk_operations#export_archives'
  post 'bulk/archive', to: 'bulk_operations#archive'
end
```

#### 6.2 前端批量选择

**添加Stimulus Controller `app/javascript/controllers/bulk_select_controller.ts`**
```typescript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "masterCheckbox", "bulkActions", "selectedCount"]
  
  connect() {
    this.updateBulkActions()
  }
  
  toggleAll() {
    const checked = this.masterCheckboxTarget.checked
    this.checkboxTargets.forEach(cb => cb.checked = checked)
    this.updateBulkActions()
  }
  
  toggle() {
    this.updateBulkActions()
  }
  
  updateBulkActions() {
    const selectedCount = this.getSelectedIds().length
    
    if (selectedCount > 0) {
      this.bulkActionsTarget.classList.remove('hidden')
      this.selectedCountTarget.textContent = selectedCount
    } else {
      this.bulkActionsTarget.classList.add('hidden')
    }
    
    // 更新全选复选框状态
    if (this.hasMasterCheckboxTarget) {
      const allChecked = this.checkboxTargets.every(cb => cb.checked)
      const someChecked = this.checkboxTargets.some(cb => cb.checked)
      
      this.masterCheckboxTarget.checked = allChecked
      this.masterCheckboxTarget.indeterminate = someChecked && !allChecked
    }
  }
  
  getSelectedIds() {
    return this.checkboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.value)
  }
  
  submitBulkAction(event) {
    event.preventDefault()
    const form = event.target
    const action = form.dataset.bulkAction
    
    const selectedIds = this.getSelectedIds()
    
    if (selectedIds.length === 0) {
      alert('请至少选择一个案件')
      return
    }
    
    if (!confirm(`确定要对选中的 ${selectedIds.length} 个案件执行此操作吗？`)) {
      return
    }
    
    // 添加case_ids到表单
    selectedIds.forEach(id => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = 'case_ids[]'
      input.value = id
      form.appendChild(input)
    })
    
    form.submit()
  }
}
```

---

### 方案七：案件关联管理

#### 7.1 关联模型

**`app/models/case_relation.rb`**
```ruby
class CaseRelation < ApplicationRecord
  belongs_to :from_case, class_name: 'Case'
  belongs_to :to_case, class_name: 'Case'
  
  validates :from_case_id, presence: true
  validates :to_case_id, presence: true
  validates :relation_type, presence: true, inclusion: { 
    in: %w[parent child related series appeal retrial] 
  }
  
  RELATION_TYPES = {
    'parent' => '原案',
    'child' => '派生案件',
    'related' => '相关案件',
    'series' => '系列案件',
    'appeal' => '上诉案件',
    'retrial' => '再审案件'
  }.freeze
  
  def relation_display
    RELATION_TYPES[relation_type]
  end
end
```

**`app/models/case.rb` 添加关联**
```ruby
has_many :case_relations_as_from, class_name: 'CaseRelation', foreign_key: 'from_case_id', dependent: :destroy
has_many :case_relations_as_to, class_name: 'CaseRelation', foreign_key: 'to_case_id', dependent: :destroy
has_many :related_cases_from, through: :case_relations_as_from, source: :to_case
has_many :related_cases_to, through: :case_relations_as_to, source: :from_case

def all_related_cases
  (related_cases_from + related_cases_to).uniq
end
```

#### 7.2 系列案件

**`app/models/case_series.rb`**
```ruby
class CaseSeries < ApplicationRecord
  belongs_to :company
  belongs_to :created_by, polymorphic: true
  
  has_many :case_series_memberships, dependent: :destroy
  has_many :cases, through: :case_series_memberships
  
  validates :name, presence: true
  
  def add_case(case_record, position: nil)
    case_series_memberships.create!(
      case: case_record,
      position: position || (case_series_memberships.maximum(:position) || 0) + 1
    )
  end
  
  def stats
    {
      total_count: cases.count,
      closed_count: cases.where(status: 'closed').count,
      active_count: cases.where(status: ['investigating', 'in_court']).count,
      pending_count: cases.where(status: 'pending').count
    }
  end
end
```

---

### 方案八：企业沟通增强

#### 8.1 问答系统

**`app/models/case_question.rb`**
```ruby
class CaseQuestion < ApplicationRecord
  belongs_to :case
  belongs_to :asker, polymorphic: true
  belongs_to :answerer, polymorphic: true, optional: true
  
  validates :question, presence: true
  
  scope :unresolved, -> { where(is_resolved: false) }
  scope :resolved, -> { where(is_resolved: true) }
  scope :unanswered, -> { where(answer: nil) }
  
  after_create :notify_lawyers
  after_update :notify_asker, if: -> { saved_change_to_answer? }
  
  def mark_as_resolved!
    update!(is_resolved: true)
  end
  
  private
  
  def notify_lawyers
    # 通知案件团队律师
    CaseNotificationService.call(
      self.case,
      'new_question',
      self.case.team_lawyers,
      content: "企业用户在案件中提出了新问题"
    )
  end
  
  def notify_asker
    # 通知提问者
    CaseNotificationService.call(
      self.case,
      'question_answered',
      [asker],
      content: "您的问题已得到律师回复"
    )
  end
end
```

**Controller**
```ruby
class CaseQuestionsController < ApplicationController
  before_action :set_case
  before_action :require_authentication
  
  def create
    @question = @case.case_questions.new(question_params)
    @question.asker = current_user_or_lawyer
    
    if @question.save
      redirect_to @case, notice: '问题已提交，律师会尽快回复'
    else
      redirect_to @case, alert: '提交失败'
    end
  end
  
  def answer
    @question = @case.case_questions.find(params[:id])
    
    unless current_lawyer
      redirect_to @case, alert: '只有律师可以回答问题'
      return
    end
    
    if @question.update(answer: params[:answer], answerer: current_lawyer, answered_at: Time.current)
      redirect_to @case, notice: '回复成功'
    else
      redirect_to @case, alert: '回复失败'
    end
  end
  
  def resolve
    @question = @case.case_questions.find(params[:id])
    @question.mark_as_resolved!
    redirect_to @case, notice: '已标记为已解决'
  end
  
  private
  
  def set_case
    @case = Case.find(params[:case_id])
  end
  
  def question_params
    params.require(:case_question).permit(:question)
  end
end
```

---

### 方案九：数据统计分析

#### 9.1 统计Service

**`app/services/case_statistics_service.rb`**
```ruby
class CaseStatisticsService < ApplicationService
  def initialize(scope: Case.all, lawyer: nil, company: nil, date_range: nil)
    @scope = scope
    @lawyer = lawyer
    @company = company
    @date_range = date_range || (1.year.ago..Date.today)
  end
  
  def call
    {
      overview: overview_stats,
      case_type_distribution: case_type_distribution,
      status_distribution: status_distribution,
      stage_distribution: stage_distribution,
      timeline_stats: timeline_stats,
      performance_metrics: performance_metrics
    }
  end
  
  private
  
  def overview_stats
    {
      total_cases: @scope.count,
      active_cases: @scope.where(status: ['investigating', 'in_court']).count,
      closed_cases: @scope.where(status: 'closed').count,
      win_rate: calculate_win_rate,
      avg_duration: calculate_avg_duration
    }
  end
  
  def case_type_distribution
    @scope.group(:case_type).count
  end
  
  def status_distribution
    @scope.group(:status).count
  end
  
  def stage_distribution
    @scope.where.not(stage: nil).group(:stage).count
  end
  
  def timeline_stats
    # 按月统计新增案件、结案案件
    months = []
    current = @date_range.begin.beginning_of_month
    
    while current <= @date_range.end
      months << {
        month: current,
        new_cases: @scope.where(created_at: current.beginning_of_month..current.end_of_month).count,
        closed_cases: @scope.where(closing_at: current.beginning_of_month..current.end_of_month).count
      }
      current = current.next_month
    end
    
    months
  end
  
  def performance_metrics
    return {} unless @lawyer
    
    {
      total_handled: @scope.filter_by_team_member(@lawyer.id).count,
      as_lead_lawyer: @scope.filter_by_lead_lawyer(@lawyer.id).count,
      avg_duration: calculate_avg_duration(@scope.filter_by_team_member(@lawyer.id)),
      win_rate: calculate_win_rate(@scope.filter_by_team_member(@lawyer.id))
    }
  end
  
  def calculate_win_rate(scope = @scope)
    closed = scope.where(status: 'closed')
    return 0 if closed.count.zero?
    
    # 简化：假设有胜诉标记字段（实际需要根据业务逻辑判断）
    # 这里返回模拟数据
    75.0
  end
  
  def calculate_avg_duration(scope = @scope)
    closed = scope.where(status: 'closed').where.not(filing_at: nil, closing_at: nil)
    return 0 if closed.count.zero?
    
    durations = closed.map { |c| (c.closing_at - c.filing_at.to_time).to_i / 1.day }
    durations.sum / durations.size
  end
end
```

#### 9.2 统计页面

**路由**
```ruby
namespace :cases do
  get 'statistics', to: 'statistics#index'
  get 'statistics/lawyer/:id', to: 'statistics#lawyer'
  get 'statistics/company/:id', to: 'statistics#company'
end
```

**Controller**
```ruby
class Cases::StatisticsController < ApplicationController
  before_action :require_authentication
  
  def index
    scope = if current_lawyer
      Case.not_deleted
    else
      current_company.cases.not_deleted
    end
    
    @stats = CaseStatisticsService.call(
      scope: scope,
      lawyer: current_lawyer,
      company: current_company
    )
  end
  
  def lawyer
    @lawyer = LawyerAccount.find(params[:id])
    @stats = CaseStatisticsService.call(
      scope: Case.not_deleted,
      lawyer: @lawyer
    )
    render :index
  end
  
  def company
    @company = Company.find(params[:id])
    @stats = CaseStatisticsService.call(
      scope: @company.cases.not_deleted,
      company: @company
    )
    render :index
  end
end
```

---

### 方案十：移动端优化

#### 10.1 移动端检测和适配

**`app/helpers/mobile_helper.rb`**
```ruby
module MobileHelper
  def mobile_device?
    request.user_agent =~ /Mobile|Android|iPhone|iPad|iPod/
  end
  
  def render_for_mobile(template_name)
    mobile_template = "#{template_name}_mobile"
    
    if mobile_device? && template_exists?(mobile_template)
      render mobile_template
    else
      render template_name
    end
  end
end
```

#### 10.2 移动端专用视图

**创建 `app/views/cases/index_mobile.html.erb`**
（精简版案件列表，适配小屏幕）

#### 10.3 语音输入支持

**添加Stimulus Controller `app/javascript/controllers/voice_input_controller.ts`**
```typescript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button"]
  
  private recognition: any
  
  connect() {
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
      this.buttonTarget.style.display = 'none'
      return
    }
    
    const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition
    this.recognition = new SpeechRecognition()
    this.recognition.lang = 'zh-CN'
    this.recognition.continuous = false
    this.recognition.interimResults = false
    
    this.recognition.onresult = (event: any) => {
      const transcript = event.results[0][0].transcript
      this.inputTarget.value = transcript
      this.buttonTarget.classList.remove('recording')
    }
    
    this.recognition.onerror = (event: any) => {
      console.error('语音识别错误:', event.error)
      this.buttonTarget.classList.remove('recording')
    }
    
    this.recognition.onend = () => {
      this.buttonTarget.classList.remove('recording')
    }
  }
  
  startRecording(event: Event) {
    event.preventDefault()
    
    this.buttonTarget.classList.add('recording')
    this.recognition.start()
  }
}
```

---

## 🔄 数据迁移策略

### 迁移步骤

1. **创建所有数据库迁移**
```bash
rails g migration AddCaseOptimizationTables
rails g migration EnhanceWorkLogsTable
rails g migration EnhanceCasesTable
```

2. **执行迁移**
```bash
rails db:migrate
```

3. **数据种子**
```ruby
# db/seeds/case_optimization.rb
# 创建工作记录模板
# 创建示例筛选条件
# ...
```

---

## 🧪 测试策略

### 单元测试
- 所有新Model的关联和验证
- Service类的业务逻辑
- Concern模块的功能

### 功能测试
- 筛选功能
- 批量操作
- 通知系统
- 统计计算

### 集成测试
- 完整的案件管理流程
- 跨模块协作

---

## 📝 实施时间线

| 阶段 | 功能 | 预计工时 | 优先级 |
|------|------|---------|--------|
| 第1天 | 数据库迁移 + 筛选搜索 | 8h | P0 |
| 第2天 | 团队协作增强 | 8h | P0 |
| 第3天 | 结构化工作记录 | 8h | P0 |
| 第4天 | 智能提醒通知 | 8h | P0 |
| 第5天 | 进度可视化（前端） | 8h | P1 |
| 第6天 | 进度可视化（后端） | 8h | P1 |
| 第7天 | 批量操作 + 案件关联 | 8h | P1 |
| 第8天 | 企业沟通增强 | 8h | P1 |
| 第9天 | 数据统计分析 | 8h | P2 |
| 第10天 | 移动端优化 | 8h | P2 |
| 第11-12天 | 全面测试和优化 | 16h | - |

**总预计工时：100小时（12.5个工作日）**

---

## ✅ 验收标准

### 功能验收
- [ ] 筛选条件可保存并复用
- [ ] 全文搜索准确无误
- [ ] 团队成员信息完整展示
- [ ] 工作记录类型齐全
- [ ] 待办事项准时提醒
- [ ] 批量操作正常工作
- [ ] 案件关联清晰展示
- [ ] 问答系统通知及时
- [ ] 统计数据准确
- [ ] 移动端体验流畅

### 性能验收
- [ ] 案件列表页加载<2秒
- [ ] 筛选操作响应<1秒
- [ ] 批量操作(100个案件)<5秒

### 兼容性验收
- [ ] 支持Chrome/Firefox/Safari最新版
- [ ] 支持iOS Safari
- [ ] 支持Android Chrome

---

## 📚 文档清单

- [x] 技术架构方案
- [ ] API文档
- [ ] 用户操作手册
- [ ] 管理员配置指南
- [ ] 数据库ER图
- [ ] 部署说明

---

**文档版本：** v1.0  
**创建日期：** 2024年  
**更新日期：** 2024年
