# 重大事项讨论板块 - 综合优化方案

## 📋 优化目标

将重大事项讨论板块从**单向咨询工具**升级为**智能协作平台**，实现：
- ✅ 真正的多方实时协作讨论
- ✅ 自动化的状态管理和智能提醒
- ✅ 完整的知识沉淀和决策记录
- ✅ 强大的搜索筛选和数据分析
- ✅ 深度的模块集成和移动体验

---

## 🏗️ 系统架构设计

### 1. 数据库模型设计

#### 1.1 MajorIssue 模型扩展
```ruby
# 新增字段
add_column :major_issues, :conclusion, :text                    # 决策结论
add_column :major_issues, :processing_days, :integer, default: 0 # 处理天数
add_column :major_issues, :followers_count, :integer, default: 0 # 关注人数
add_column :major_issues, :views_count, :integer, default: 0     # 浏览次数
add_column :major_issues, :related_record_type, :string          # 关联模块类型
add_column :major_issues, :related_record_id, :integer           # 关联模块ID
add_column :major_issues, :share_token, :string                  # 分享令牌
add_column :major_issues, :share_expires_at, :datetime           # 分享过期时间
```

#### 1.2 Comment 模型扩展
```ruby
# 评论增强
add_column :comments, :is_pinned, :boolean, default: false       # 置顶标记
add_column :comments, :pinned_at, :datetime                      # 置顶时间
add_column :comments, :pinned_by_id, :integer                    # 置顶人ID
add_column :comments, :mentioned_user_ids, :jsonb, default: []   # @提到的用户
add_column :comments, :is_key_opinion, :boolean, default: false  # 关键意见标记
```

#### 1.3 新增关联表

**MajorIssueAttachment - 附件增强**
```ruby
create_table :major_issue_attachments do |t|
  t.references :major_issue, foreign_key: true
  t.string :category                    # 分类：contract/financial/evidence/legal/other
  t.integer :version, default: 1        # 版本号
  t.string :original_filename           # 原始文件名
  t.bigint :active_storage_blob_id      # 关联ActiveStorage
  t.boolean :is_latest, default: true   # 是否最新版本
  t.timestamps
end
```

**MajorIssueFollower - 关注功能**
```ruby
create_table :major_issue_followers do |t|
  t.references :major_issue, foreign_key: true
  t.references :user, polymorphic: true, index: true  # lawyer 或 company_user
  t.boolean :notify_new_comment, default: true        # 新评论通知
  t.boolean :notify_status_change, default: true      # 状态变更通知
  t.timestamps
end
```

**MajorIssueReadStatus - 阅读状态**
```ruby
create_table :major_issue_read_statuses do |t|
  t.references :major_issue, foreign_key: true
  t.references :user, polymorphic: true, index: true
  t.datetime :last_read_at                            # 最后阅读时间
  t.integer :last_read_comment_id                     # 最后阅读评论ID
  t.integer :unread_count, default: 0                 # 未读评论数
  t.timestamps
end
```

**MajorIssueTodoItem - 关联待办**
```ruby
create_table :major_issue_todo_items do |t|
  t.references :major_issue, foreign_key: true
  t.string :title
  t.text :description
  t.string :status, default: 'pending'  # pending/in_progress/completed
  t.references :assignee, polymorphic: true
  t.date :due_date
  t.timestamps
end
```

**SavedFilter - 保存的筛选条件**
```ruby
create_table :saved_filters do |t|
  t.references :user, polymorphic: true, index: true
  t.string :name                        # 筛选器名称
  t.jsonb :conditions                   # 筛选条件JSON
  t.string :filterable_type             # MajorIssue/Contract/Case
  t.boolean :is_default, default: false
  t.timestamps
end
```

---

## 🎯 功能模块详细设计

### 模块一：多方实时讨论系统

#### 1.1 评论权限开放
```ruby
# app/models/comment.rb
class Comment < ApplicationRecord
  # 原来只有律师可以评论，现在企业用户也可以
  belongs_to :author, polymorphic: true  # lawyer_account 或 company_user
  
  # 新增功能
  has_many :mentions, class_name: 'CommentMention', dependent: :destroy
  has_many :mentioned_users, through: :mentions, source: :user, source_type: 'User'
  
  scope :pinned, -> { where(is_pinned: true).order(pinned_at: :desc) }
  scope :key_opinions, -> { where(is_key_opinion: true) }
  scope :regular, -> { where(is_pinned: false) }
  
  # @提醒解析
  before_save :parse_mentions
  after_create :notify_mentioned_users
  after_create :broadcast_new_comment
  
  private
  
  def parse_mentions
    # 解析 @username 格式
    self.mentioned_user_ids = content.scan(/@(\w+)/).flatten.map do |username|
      # 查找用户ID（lawyer或company_user）
      find_user_by_username(username)&.id
    end.compact
  end
  
  def notify_mentioned_users
    mentioned_users.each do |user|
      MajorIssueNotificationJob.perform_later(
        user: user,
        issue: commentable,
        type: 'mentioned',
        comment: self
      )
    end
  end
  
  def broadcast_new_comment
    ActionCable.server.broadcast(
      "major_issue_#{commentable_id}",
      {
        type: 'new_comment',
        comment_id: id,
        author_name: author.name,
        content: content,
        created_at: created_at.iso8601,
        html: ApplicationController.render(
          partial: 'comments/comment',
          locals: { comment: self }
        )
      }
    )
  end
end
```

#### 1.2 实时推送 - ActionCable Channel
```ruby
# app/channels/major_issue_channel.rb
class MajorIssueChannel < ApplicationCable::Channel
  def subscribed
    issue = MajorIssue.find(params[:issue_id])
    stream_from "major_issue_#{issue.id}"
    
    # 更新阅读状态
    update_read_status(issue)
  end
  
  def unsubscribed
    # 清理工作
  end
  
  def typing(data)
    # 广播"正在输入"状态
    ActionCable.server.broadcast(
      "major_issue_#{params[:issue_id]}",
      {
        type: 'user_typing',
        user_name: current_user.name
      }
    )
  end
  
  private
  
  def update_read_status(issue)
    MajorIssueReadStatus.find_or_create_by(
      major_issue: issue,
      user: current_user
    ).update(
      last_read_at: Time.current,
      last_read_comment_id: issue.comments.last&.id,
      unread_count: 0
    )
  end
end
```

#### 1.3 前端 Stimulus Controller
```typescript
// app/javascript/controllers/major_issue_discussion_controller.ts
import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
  static values = {
    issueId: Number,
    currentUserId: Number
  }
  
  static targets = ["commentsList", "unreadBadge", "typingIndicator"]
  
  channel: any
  
  connect() {
    this.subscribeToChannel()
  }
  
  disconnect() {
    this.channel?.unsubscribe()
  }
  
  subscribeToChannel() {
    this.channel = consumer.subscriptions.create(
      {
        channel: "MajorIssueChannel",
        issue_id: this.issueIdValue
      },
      {
        received: (data: any) => {
          this.handleIncomingMessage(data)
        }
      }
    )
  }
  
  handleIncomingMessage(data: any) {
    switch (data.type) {
      case 'new_comment':
        this.appendNewComment(data)
        break
      case 'user_typing':
        this.showTypingIndicator(data.user_name)
        break
      case 'status_changed':
        this.updateStatusBadge(data.new_status)
        break
    }
  }
  
  appendNewComment(data: any) {
    // 添加新评论到列表
    this.commentsListTarget.insertAdjacentHTML('beforeend', data.html)
    
    // 播放提示音
    this.playNotificationSound()
    
    // 滚动到底部
    this.scrollToBottom()
  }
  
  showTypingIndicator(userName: string) {
    this.typingIndicatorTarget.textContent = `${userName} 正在输入...`
    this.typingIndicatorTarget.classList.remove('hidden')
    
    // 3秒后隐藏
    setTimeout(() => {
      this.typingIndicatorTarget.classList.add('hidden')
    }, 3000)
  }
  
  // 用户输入时发送typing事件
  onInput() {
    this.channel.perform('typing', {})
  }
}
```

---

### 模块二：智能状态管理系统

#### 2.1 自动状态流转
```ruby
# app/models/major_issue.rb
class MajorIssue < ApplicationRecord
  # 状态机
  include AASM
  
  aasm column: :status do
    state :pending, initial: true
    state :discussing
    state :resolved
    state :archived
    
    # 有第一条评论时自动进入讨论中
    event :start_discussion do
      transitions from: :pending, to: :discussing
    end
    
    # 标记为已解决
    event :mark_resolved do
      transitions from: [:pending, :discussing], to: :resolved, 
                  after: :set_resolved_at
    end
    
    # 归档
    event :archive do
      transitions from: :resolved, to: :archived
    end
  end
  
  # 评论后自动更新状态
  after_create :auto_start_discussion, if: -> { comments.any? && pending? }
  
  # 每天计算处理天数
  def update_processing_days!
    if resolved?
      days = (resolved_at - created_at) / 1.day
    else
      days = (Time.current - created_at) / 1.day
    end
    update_column(:processing_days, days.to_i)
  end
  
  # 是否超时
  def overdue?
    return false if resolved? || archived?
    
    case priority
    when 'urgent'
      created_at < 1.day.ago
    when 'high'
      created_at < 3.days.ago
    when 'medium'
      created_at < 7.days.ago
    else
      false
    end
  end
  
  # 超时天数
  def overdue_days
    return 0 unless overdue?
    
    deadline = case priority
    when 'urgent' then 1
    when 'high' then 3
    when 'medium' then 7
    else 0
    end
    
    ((Time.current - created_at) / 1.day).to_i - deadline
  end
end
```

#### 2.2 智能提醒任务
```ruby
# app/jobs/major_issue_reminder_job.rb
class MajorIssueReminderJob < ApplicationJob
  queue_as :default
  
  def perform
    # 提醒1：紧急事项超时未讨论
    remind_urgent_pending_issues
    
    # 提醒2：讨论中事项长时间无新回复
    remind_stale_discussions
    
    # 提醒3：待律师答复的事项
    remind_pending_lawyer_review
  end
  
  private
  
  def remind_urgent_pending_issues
    MajorIssue.pending.where(priority: 'urgent')
              .where('created_at < ?', 1.day.ago)
              .find_each do |issue|
      # 通知相关律师
      notify_lawyers(issue, '紧急事项超过1天未处理')
    end
  end
  
  def remind_stale_discussions
    MajorIssue.discussing.find_each do |issue|
      last_comment_at = issue.comments.maximum(:created_at)
      next unless last_comment_at && last_comment_at < 7.days.ago
      
      # 通知发起人
      notify_creator(issue, '该讨论已7天无新回复')
    end
  end
  
  def remind_pending_lawyer_review
    MajorIssue.pending_lawyer_review.find_each do |issue|
      next unless issue.overdue_for_review?
      
      # 通知被@的律师或所有律师
      notify_mentioned_or_all_lawyers(issue, '待答复事项已超时')
    end
  end
end

# config/recurring.yml
major_issue_reminder:
  cron: "0 9 * * *"  # 每天早上9点执行
  class: "MajorIssueReminderJob"
```

#### 2.3 进度追踪显示
```erb
<!-- app/views/major_issues/show.html.erb 新增进度卡片 -->
<div class="card card-elevated">
  <div class="card-header">
    <h3 class="card-title">
      <%= lucide_icon "activity", class: "w-5 h-5 mr-2" %>
      处理进度
    </h3>
  </div>
  <div class="card-body space-y-4">
    <!-- 处理天数 -->
    <div>
      <div class="flex items-center justify-between mb-2">
        <span class="text-sm text-secondary">处理天数</span>
        <span class="text-lg font-bold text-primary"><%= @major_issue.processing_days %>天</span>
      </div>
      <div class="w-full bg-surface-secondary rounded-full h-2">
        <% progress = [@major_issue.processing_days * 10, 100].min %>
        <div class="bg-primary h-2 rounded-full transition-all" style="width: <%= progress %>%"></div>
      </div>
    </div>
    
    <!-- 平均处理时长对比 -->
    <% avg_days = MajorIssue.resolved.average(:processing_days).to_i %>
    <div class="text-sm text-secondary">
      <% if @major_issue.resolved? %>
        <span class="text-success">✓ 已解决</span> · 
        平均处理时长 <%= avg_days %> 天
      <% elsif @major_issue.processing_days > avg_days %>
        <span class="text-warning">⚠ 已超过平均处理时长</span>
      <% else %>
        <span class="text-info">进行中</span> · 
        平均处理时长 <%= avg_days %> 天
      <% end %>
    </div>
    
    <!-- 超时警告 -->
    <% if @major_issue.overdue? %>
      <div class="alert alert-warning p-3">
        <%= lucide_icon "alert-triangle", class: "w-4 h-4 inline mr-1" %>
        该事项已超时 <strong><%= @major_issue.overdue_days %></strong> 天，请尽快处理！
      </div>
    <% end %>
    
    <!-- 快捷状态操作 -->
    <div class="flex gap-2">
      <% if @major_issue.pending? %>
        <%= button_to "开始讨论", start_discussion_major_issue_path(@major_issue), 
            method: :post, class: "btn btn-primary btn-sm flex-1" %>
      <% elsif @major_issue.discussing? %>
        <%= button_to "标记解决", mark_resolved_major_issue_path(@major_issue), 
            method: :post, class: "btn btn-success btn-sm flex-1" %>
      <% elsif @major_issue.resolved? %>
        <%= button_to "归档", archive_major_issue_path(@major_issue), 
            method: :post, class: "btn btn-secondary btn-sm flex-1" %>
      <% end %>
    </div>
  </div>
</div>
```

---

### 模块三：决策记录与知识沉淀

#### 3.1 结论字段与置顶评论
```erb
<!-- 详情页顶部显示决策结论 -->
<% if @major_issue.resolved? && @major_issue.conclusion.present? %>
  <div class="card card-elevated bg-success/10 border-success mb-6">
    <div class="card-body">
      <div class="flex items-start gap-3">
        <%= lucide_icon "check-circle", class: "w-6 h-6 text-success flex-shrink-0 mt-1" %>
        <div class="flex-1">
          <h3 class="font-heading text-lg font-semibold text-success mb-2">最终决策</h3>
          <div class="prose prose-sm">
            <%= simple_format(@major_issue.conclusion) %>
          </div>
        </div>
      </div>
    </div>
  </div>
<% end %>

<!-- 置顶评论区 -->
<% if @pinned_comments.any? %>
  <div class="mb-6">
    <h3 class="font-heading text-lg font-semibold text-primary mb-3 flex items-center gap-2">
      <%= lucide_icon "pin", class: "w-5 h-5" %>
      关键意见
    </h3>
    <div class="space-y-3">
      <% @pinned_comments.each do |comment| %>
        <div class="card card-elevated border-warning">
          <%= render 'comments/comment', comment: comment, show_pin_badge: true %>
        </div>
      <% end %>
    </div>
  </div>
<% end %>

<!-- 标记为已解决时的表单 -->
<%= form_with model: @major_issue, url: mark_resolved_major_issue_path(@major_issue), method: :post do |f| %>
  <div class="form-group">
    <%= f.label :conclusion, "决策结论", class: "form-label required" %>
    <%= f.text_area :conclusion, 
        class: "form-textarea", 
        rows: 4, 
        placeholder: "请总结本次讨论的最终决策和执行计划...",
        required: true %>
    <p class="form-help">此结论将显示在事项详情页顶部，方便后续查阅</p>
  </div>
  
  <div class="flex gap-2">
    <%= f.submit "确认标记为已解决", class: "btn btn-success" %>
    <%= link_to "取消", major_issue_path(@major_issue), class: "btn btn-secondary" %>
  </div>
<% end %>
```

#### 3.2 评论操作增强
```erb
<!-- app/views/comments/_comment.html.erb -->
<div class="border-l-4 <%= comment.is_pinned ? 'border-warning bg-warning/5' : 'border-primary' %> pl-4 py-3" 
     data-comment-id="<%= comment.id %>">
  <div class="flex items-center justify-between mb-2">
    <div class="flex items-center gap-2">
      <span class="font-semibold text-primary"><%= comment.author_name %></span>
      <span class="badge badge-secondary badge-sm">
        <%= comment.author_role == 'lawyer' ? '律师' : '助理' %>
      </span>
      <% if comment.is_pinned %>
        <span class="badge badge-warning badge-sm">
          <%= lucide_icon "pin", class: "w-3 h-3 inline mr-1" %>
          已置顶
        </span>
      <% end %>
      <% if comment.is_key_opinion %>
        <span class="badge badge-info badge-sm">
          <%= lucide_icon "star", class: "w-3 h-3 inline mr-1" %>
          关键意见
        </span>
      <% end %>
      <span class="text-sm text-secondary"><%= time_ago_in_words(comment.created_at) %>前</span>
    </div>
    
    <!-- 操作按钮 -->
    <div class="flex items-center gap-2">
      <% if can_pin_comment?(comment) %>
        <%= button_to toggle_pin_comment_path(comment), 
            method: :post,
            class: "text-warning hover:opacity-80",
            title: comment.is_pinned ? "取消置顶" : "置顶此评论" do %>
          <%= lucide_icon "pin", class: "w-4 h-4" %>
        <% end %>
      <% end %>
      
      <% if can_mark_key_opinion?(comment) %>
        <%= button_to toggle_key_opinion_comment_path(comment), 
            method: :post,
            class: "text-info hover:opacity-80",
            title: comment.is_key_opinion ? "取消标记" : "标记为关键意见" do %>
          <%= lucide_icon "star", class: "w-4 h-4" %>
        <% end %>
      <% end %>
      
      <% if comment.deletable_by?(current_user) %>
        <%= link_to comment_path(comment), 
            data: { turbo_method: :delete, turbo_confirm: "确定删除该评论吗？" },
            class: "text-danger hover:opacity-80",
            title: "删除评论" do %>
          <%= lucide_icon "trash-2", class: "w-4 h-4" %>
        <% end %>
      <% end %>
    </div>
  </div>
  
  <div class="prose prose-sm">
    <%= simple_format(comment.content) %>
  </div>
  
  <!-- @提到的用户 -->
  <% if comment.mentioned_user_ids.any? %>
    <div class="mt-2 text-sm text-secondary">
      提到了：
      <% comment.mentioned_users.each do |user| %>
        <span class="badge badge-secondary badge-sm">@<%= user.name %></span>
      <% end %>
    </div>
  <% end %>
  
  <% if comment.attachments.attached? %>
    <div class="flex flex-col gap-2 mt-3">
      <% comment.attachments.each do |attachment| %>
        <%= smart_file_link(attachment, action_buttons: true, show_size: true) %>
      <% end %>
    </div>
  <% end %>
</div>
```

---

### 模块四：高级搜索与筛选

#### 4.1 筛选面板设计
```erb
<!-- app/views/major_issues/_filter_panel.html.erb -->
<div class="card card-elevated mb-6" data-controller="major-issue-filter">
  <div class="card-body">
    <!-- 快捷标签 -->
    <div class="flex flex-wrap gap-2 mb-4">
      <%= link_to major_issues_path(status: 'pending'), 
          class: "badge #{params[:status] == 'pending' ? 'badge-warning' : 'badge-secondary'} badge-lg" do %>
        待讨论 (<%= @pending_count %>)
      <% end %>
      
      <%= link_to major_issues_path(status: 'discussing'), 
          class: "badge #{params[:status] == 'discussing' ? 'badge-info' : 'badge-secondary'} badge-lg" do %>
        讨论中 (<%= @discussing_count %>)
      <% end %>
      
      <%= link_to major_issues_path(priority: 'urgent'), 
          class: "badge #{params[:priority] == 'urgent' ? 'badge-danger' : 'badge-secondary'} badge-lg" do %>
        紧急 (<%= @urgent_count %>)
      <% end %>
      
      <%= link_to major_issues_path(filter: 'following'), 
          class: "badge #{params[:filter] == 'following' ? 'badge-primary' : 'badge-secondary'} badge-lg" do %>
        <%= lucide_icon "star", class: "w-3 h-3 inline mr-1" %>
        我关注的 (<%= @following_count %>)
      <% end %>
      
      <%= link_to major_issues_path(filter: 'mentioned'), 
          class: "badge #{params[:filter] == 'mentioned' ? 'badge-primary' : 'badge-secondary'} badge-lg" do %>
        <%= lucide_icon "at-sign", class: "w-3 h-3 inline mr-1" %>
        @我的 (<%= @mentioned_count %>)
      <% end %>
    </div>
    
    <!-- 高级筛选 -->
    <%= form_with url: major_issues_path, method: :get, 
        data: { turbo_frame: "major_issues_list" } do |f| %>
      <div class="grid md:grid-cols-4 gap-4">
        <!-- 状态多选 -->
        <div class="form-group">
          <%= f.label :statuses, "状态", class: "form-label" %>
          <%= f.select :statuses,
              options_for_select([
                ['待讨论', 'pending'],
                ['讨论中', 'discussing'],
                ['已解决', 'resolved'],
                ['已归档', 'archived']
              ], params[:statuses]),
              { include_blank: '全部' },
              class: "form-select",
              multiple: true %>
        </div>
        
        <!-- 优先级多选 -->
        <div class="form-group">
          <%= f.label :priorities, "优先级", class: "form-label" %>
          <%= f.select :priorities,
              options_for_select([
                ['紧急', 'urgent'],
                ['高', 'high'],
                ['中', 'medium'],
                ['低', 'low']
              ], params[:priorities]),
              { include_blank: '全部' },
              class: "form-select",
              multiple: true %>
        </div>
        
        <!-- 事项类型 -->
        <div class="form-group">
          <%= f.label :issue_type, "事项类型", class: "form-label" %>
          <%= f.select :issue_type,
              options_for_select([
                ['法律风险', '法律风险'],
                ['财务问题', '财务问题'],
                ['战略决策', '战略决策'],
                ['人事变动', '人事变动'],
                ['合规审查', '合规审查'],
                ['商业谈判', '商业谈判'],
                ['其他', '其他']
              ], params[:issue_type]),
              { include_blank: '全部类型' },
              class: "form-select" %>
        </div>
        
        <!-- 日期范围 -->
        <div class="form-group">
          <%= f.label :date_range, "创建时间", class: "form-label" %>
          <%= f.select :date_range,
              options_for_select([
                ['今天', 'today'],
                ['本周', 'this_week'],
                ['本月', 'this_month'],
                ['近3个月', 'last_3_months'],
                ['全部', 'all']
              ], params[:date_range] || 'all'),
              {},
              class: "form-select" %>
        </div>
      </div>
      
      <div class="flex items-center gap-2 mt-4">
        <%= f.submit "应用筛选", class: "btn btn-primary btn-sm" %>
        <%= link_to "清除筛选", major_issues_path, class: "btn btn-secondary btn-sm" %>
        
        <!-- 保存筛选条件 -->
        <button type="button" 
                data-action="click->major-issue-filter#saveFilter"
                class="btn btn-secondary btn-sm ml-auto">
          <%= lucide_icon "save", class: "w-4 h-4 mr-1" %>
          保存筛选条件
        </button>
      </div>
    <% end %>
    
    <!-- 已保存的筛选条件 -->
    <% if @saved_filters.any? %>
      <div class="mt-4 pt-4 border-t">
        <p class="text-sm text-secondary mb-2">已保存的筛选：</p>
        <div class="flex flex-wrap gap-2">
          <% @saved_filters.each do |filter| %>
            <%= link_to filter.name, 
                major_issues_path(saved_filter_id: filter.id),
                class: "badge badge-primary badge-sm" %>
          <% end %>
        </div>
      </div>
    <% end %>
  </div>
</div>
```

#### 4.2 Controller 筛选逻辑
```ruby
# app/controllers/major_issues_controller.rb
def index
  @major_issues = apply_filters(base_scope)
                    .not_deleted
                    .ordered
                    .page(params[:page])
  
  # 统计数据
  calculate_statistics
  
  # 已保存的筛选条件
  @saved_filters = current_user.saved_filters.where(filterable_type: 'MajorIssue')
end

private

def apply_filters(scope)
  scope = scope.where(status: params[:statuses]) if params[:statuses].present?
  scope = scope.where(priority: params[:priorities]) if params[:priorities].present?
  scope = scope.where(issue_type: params[:issue_type]) if params[:issue_type].present?
  
  # 日期范围
  scope = apply_date_filter(scope, params[:date_range]) if params[:date_range].present?
  
  # 特殊筛选
  case params[:filter]
  when 'following'
    # 我关注的
    scope = scope.joins(:followers).where(major_issue_followers: { user: current_user })
  when 'mentioned'
    # @我的
    scope = scope.where('mentioned_lawyer_id = ? OR id IN (?)', 
                        current_user.id, 
                        current_user.mentioned_in_comment_issue_ids)
  when 'unread'
    # 有未读评论的
    scope = scope.joins(:read_statuses)
                 .where(major_issue_read_statuses: { user: current_user })
                 .where('major_issue_read_statuses.unread_count > 0')
  end
  
  # 使用已保存的筛选条件
  if params[:saved_filter_id].present?
    filter = current_user.saved_filters.find(params[:saved_filter_id])
    scope = apply_saved_filter(scope, filter.conditions)
  end
  
  scope
end

def apply_date_filter(scope, range)
  case range
  when 'today'
    scope.where('created_at >= ?', Date.today)
  when 'this_week'
    scope.where('created_at >= ?', Date.today.beginning_of_week)
  when 'this_month'
    scope.where('created_at >= ?', Date.today.beginning_of_month)
  when 'last_3_months'
    scope.where('created_at >= ?', 3.months.ago)
  else
    scope
  end
end
```

---

### 模块五：附件分类与版本管理

#### 5.1 附件上传时分类
```erb
<!-- app/views/major_issues/_form.html.erb -->
<div class="mb-6">
  <h3 class="font-heading text-lg font-semibold text-primary mb-4">相关材料</h3>
  
  <div id="attachments-container" data-controller="attachment-uploader">
    <!-- 附件项模板 -->
    <template data-attachment-uploader-target="template">
      <div class="border rounded-lg p-4 mb-3 bg-surface-secondary">
        <div class="grid md:grid-cols-2 gap-4">
          <div class="form-group">
            <label class="form-label">选择文件</label>
            <input type="file" 
                   name="major_issue[attachments_attributes][][file]"
                   class="form-input"
                   accept=".pdf,.doc,.docx,.xls,.xlsx,.jpg,.jpeg,.png">
          </div>
          
          <div class="form-group">
            <label class="form-label">文件分类</label>
            <select name="major_issue[attachments_attributes][][category]" 
                    class="form-select">
              <option value="contract">合同文档</option>
              <option value="financial">财务报表</option>
              <option value="evidence">证据材料</option>
              <option value="legal">法律意见</option>
              <option value="other">其他</option>
            </select>
          </div>
        </div>
        
        <button type="button" 
                data-action="click->attachment-uploader#removeItem"
                class="btn btn-danger btn-sm mt-2">
          <%= lucide_icon "trash-2", class: "w-4 h-4 mr-1" %>
          移除
        </button>
      </div>
    </template>
    
    <div data-attachment-uploader-target="container"></div>
    
    <button type="button" 
            data-action="click->attachment-uploader#addItem"
            class="btn btn-secondary btn-sm">
      <%= lucide_icon "plus", class: "w-4 h-4 mr-1" %>
      添加附件
    </button>
  </div>
</div>
```

#### 5.2 附件展示（按分类分组）
```erb
<!-- app/views/major_issues/show.html.erb -->
<% if @major_issue.attachments_grouped_by_category.any? %>
  <div class="card card-elevated">
    <div class="card-header">
      <h2 class="card-title">
        <%= lucide_icon "paperclip", class: "w-5 h-5 mr-2" %>
        相关材料
      </h2>
      <div class="flex gap-2">
        <%= link_to "批量下载", 
            download_all_attachments_major_issue_path(@major_issue),
            class: "btn btn-success btn-sm" %>
      </div>
    </div>
    <div class="card-body">
      <% @major_issue.attachments_grouped_by_category.each do |category, attachments| %>
        <div class="mb-6 last:mb-0">
          <h4 class="font-semibold text-primary mb-3 flex items-center gap-2">
            <%= category_icon(category) %>
            <%= category_name(category) %>
            <span class="badge badge-secondary badge-sm"><%= attachments.count %></span>
          </h4>
          
          <div class="space-y-2">
            <% attachments.each do |attachment| %>
              <div class="flex items-center justify-between p-3 bg-surface-secondary rounded-lg group">
                <div class="flex items-center gap-3 flex-1">
                  <%= file_type_icon(attachment.filename.extension) %>
                  <div class="flex-1">
                    <p class="font-medium text-primary">
                      <%= attachment.original_filename %>
                      <% if attachment.version > 1 %>
                        <span class="badge badge-info badge-sm ml-2">v<%= attachment.version %></span>
                      <% end %>
                      <% if attachment.is_latest %>
                        <span class="badge badge-success badge-sm ml-1">最新</span>
                      <% end %>
                    </p>
                    <div class="flex items-center gap-3 text-sm text-secondary">
                      <span><%= number_to_human_size(attachment.blob.byte_size) %></span>
                      <span><%= attachment.created_at.strftime('%Y-%m-%d %H:%M') %></span>
                    </div>
                  </div>
                </div>
                
                <div class="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                  <%= smart_file_link(attachment.blob, action_buttons: true) %>
                  
                  <!-- 查看历史版本 -->
                  <% if attachment.has_previous_versions? %>
                    <%= link_to "历史版本", 
                        attachment_versions_path(attachment),
                        class: "btn btn-secondary btn-sm" %>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
  </div>
<% end %>
```

---

### 模块六：协作集成

#### 6.1 关联其他模块
```ruby
# app/models/major_issue.rb
belongs_to :related_record, polymorphic: true, optional: true

# 快速创建关联
def link_to_contract(contract)
  update(related_record: contract)
end

def link_to_case(kase)
  update(related_record: kase)
end
```

```erb
<!-- 详情页显示关联 -->
<% if @major_issue.related_record.present? %>
  <div class="card card-elevated">
    <div class="card-header">
      <h3 class="card-title">关联记录</h3>
    </div>
    <div class="card-body">
      <div class="flex items-center gap-3">
        <%= lucide_icon "link", class: "w-5 h-5 text-primary" %>
        <div class="flex-1">
          <p class="text-sm text-secondary">关联类型</p>
          <p class="font-medium text-primary">
            <%= @major_issue.related_record_type == 'Contract' ? '合同' : '案件' %>
          </p>
        </div>
        <%= link_to "查看详情", 
            polymorphic_path(@major_issue.related_record),
            class: "btn btn-primary btn-sm" %>
      </div>
    </div>
  </div>
<% end %>
```

#### 6.2 快速创建待办
```erb
<!-- 讨论区添加"创建待办"按钮 -->
<div class="border-t pt-4 mt-4">
  <h4 class="font-semibold text-primary mb-3">后续行动</h4>
  
  <%= form_with model: [@major_issue, MajorIssueTodoItem.new], 
      url: major_issue_todo_items_path(@major_issue) do |f| %>
    <div class="grid md:grid-cols-2 gap-4">
      <div class="form-group">
        <%= f.label :title, "待办事项", class: "form-label" %>
        <%= f.text_field :title, class: "form-input", placeholder: "例如：起草补充协议" %>
      </div>
      
      <div class="form-group">
        <%= f.label :due_date, "截止日期", class: "form-label" %>
        <%= f.date_field :due_date, class: "form-input" %>
      </div>
    </div>
    
    <div class="form-group">
      <%= f.label :assignee_id, "指派给", class: "form-label" %>
      <%= f.select :assignee_id,
          options_for_select(assignable_users, current_user.id),
          {},
          class: "form-select" %>
    </div>
    
    <%= f.submit "创建待办", class: "btn btn-primary btn-sm" %>
  <% end %>
  
  <!-- 已创建的待办列表 -->
  <% if @major_issue.todo_items.any? %>
    <div class="mt-4 space-y-2">
      <% @major_issue.todo_items.each do |todo| %>
        <div class="flex items-center gap-3 p-3 bg-surface-secondary rounded-lg">
          <input type="checkbox" 
                 <%= 'checked' if todo.completed? %>
                 data-action="change->todo#toggle"
                 data-todo-id="<%= todo.id %>">
          <div class="flex-1">
            <p class="font-medium text-primary <%= 'line-through' if todo.completed? %>">
              <%= todo.title %>
            </p>
            <p class="text-sm text-secondary">
              指派给：<%= todo.assignee.name %> · 
              截止：<%= todo.due_date.strftime('%Y-%m-%d') %>
            </p>
          </div>
        </div>
      <% end %>
    </div>
  <% end %>
</div>
```

#### 6.3 外部分享链接
```ruby
# app/controllers/major_issues_controller.rb
def generate_share_link
  @major_issue.update(
    share_token: SecureRandom.urlsafe_base64,
    share_expires_at: 7.days.from_now
  )
  
  render json: { 
    share_url: shared_major_issue_url(@major_issue.share_token)
  }
end

def shared_view
  @major_issue = MajorIssue.find_by!(share_token: params[:token])
  
  if @major_issue.share_expires_at < Time.current
    render :expired
  else
    render :show, layout: 'shared'
  end
end
```

---

### 模块七：数据分析报表

#### 7.1 统计仪表板
```erb
<!-- app/views/major_issues/analytics.html.erb -->
<div class="container-main">
  <h1 class="font-heading text-3xl font-bold text-primary mb-6">重大事项数据分析</h1>
  
  <div class="grid md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
    <!-- KPI卡片 -->
    <div class="card card-elevated">
      <div class="card-body text-center">
        <p class="text-sm text-secondary mb-1">平均处理时长</p>
        <p class="font-heading text-3xl font-bold text-primary">
          <%= @avg_processing_days %> 天
        </p>
        <p class="text-xs text-secondary mt-1">
          <span class="<%= @processing_trend > 0 ? 'text-danger' : 'text-success' %>">
            <%= @processing_trend > 0 ? '↑' : '↓' %>
            <%= @processing_trend.abs %>%
          </span>
          较上月
        </p>
      </div>
    </div>
    
    <div class="card card-elevated">
      <div class="card-body text-center">
        <p class="text-sm text-secondary mb-1">本月新增</p>
        <p class="font-heading text-3xl font-bold text-info"><%= @this_month_count %></p>
      </div>
    </div>
    
    <div class="card card-elevated">
      <div class="card-body text-center">
        <p class="text-sm text-secondary mb-1">本月解决</p>
        <p class="font-heading text-3xl font-bold text-success"><%= @this_month_resolved %></p>
      </div>
    </div>
    
    <div class="card card-elevated">
      <div class="card-body text-center">
        <p class="text-sm text-secondary mb-1">解决率</p>
        <p class="font-heading text-3xl font-bold text-primary">
          <%= (@this_month_resolved.to_f / @this_month_count * 100).round %>%
        </p>
      </div>
    </div>
  </div>
  
  <!-- 图表区域 -->
  <div class="grid md:grid-cols-2 gap-6 mb-8">
    <!-- 处理时长趋势 -->
    <div class="card card-elevated">
      <div class="card-header">
        <h3 class="card-title">处理时长趋势（近6个月）</h3>
      </div>
      <div class="card-body">
        <%= line_chart @processing_days_trend, 
            library: { 
              scales: { 
                y: { title: { display: true, text: '天数' } } 
              } 
            } %>
      </div>
    </div>
    
    <!-- 事项类型分布 -->
    <div class="card card-elevated">
      <div class="card-header">
        <h3 class="card-title">事项类型分布</h3>
      </div>
      <div class="card-body">
        <%= pie_chart @issue_type_distribution %>
      </div>
    </div>
  </div>
  
  <!-- 律师工作量统计 -->
  <div class="card card-elevated mb-8">
    <div class="card-header">
      <h3 class="card-title">律师工作量统计</h3>
    </div>
    <div class="card-body">
      <div class="table-container">
        <table class="table">
          <thead>
            <tr>
              <th>律师</th>
              <th>答复事项数</th>
              <th>平均响应时间</th>
              <th>评论数</th>
              <th>本月工作量</th>
            </tr>
          </thead>
          <tbody>
            <% @lawyer_stats.each do |stat| %>
              <tr>
                <td><%= stat[:lawyer_name] %></td>
                <td><%= stat[:reviewed_count] %></td>
                <td><%= stat[:avg_response_hours] %>小时</td>
                <td><%= stat[:comments_count] %></td>
                <td>
                  <div class="w-full bg-surface-secondary rounded-full h-2">
                    <div class="bg-primary h-2 rounded-full" 
                         style="width: <%= stat[:workload_percentage] %>%"></div>
                  </div>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
  </div>
  
  <!-- 预警指标 -->
  <div class="card card-elevated">
    <div class="card-header">
      <h3 class="card-title">预警指标</h3>
    </div>
    <div class="card-body">
      <div class="grid md:grid-cols-3 gap-4">
        <div class="p-4 bg-danger/10 border border-danger/30 rounded-lg">
          <div class="flex items-center gap-3">
            <%= lucide_icon "alert-triangle", class: "w-8 h-8 text-danger" %>
            <div>
              <p class="text-sm text-secondary">超时事项</p>
              <p class="text-2xl font-bold text-danger"><%= @overdue_count %></p>
            </div>
          </div>
        </div>
        
        <div class="p-4 bg-warning/10 border border-warning/30 rounded-lg">
          <div class="flex items-center gap-3">
            <%= lucide_icon "clock", class: "w-8 h-8 text-warning" %>
            <div>
              <p class="text-sm text-secondary">长期未解决</p>
              <p class="text-2xl font-bold text-warning"><%= @long_pending_count %></p>
            </div>
          </div>
        </div>
        
        <div class="p-4 bg-info/10 border border-info/30 rounded-lg">
          <div class="flex items-center gap-3">
            <%= lucide_icon "message-square", class: "w-8 h-8 text-info" %>
            <div>
              <p class="text-sm text-secondary">讨论停滞</p>
              <p class="text-2xl font-bold text-info"><%= @stale_discussion_count %></p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
```

---

### 模块八：移动端优化

#### 8.1 响应式布局优化
```erb
<!-- 移动端优化的列表卡片 -->
<div class="card card-elevated hover:shadow-lg transition-shadow">
  <div class="card-body">
    <!-- 移动端：垂直布局 -->
    <div class="flex flex-col md:flex-row md:items-start md:justify-between gap-3">
      <div class="flex-1">
        <div class="flex flex-wrap items-center gap-2 mb-2">
          <!-- 移动端显示公司名 -->
          <% if @company.nil? %>
            <span class="badge badge-secondary badge-sm md:hidden">
              <%= issue.company.name %>
            </span>
          <% end %>
          
          <h3 class="font-heading text-lg md:text-xl font-semibold text-primary">
            <%= issue.title %>
          </h3>
        </div>
        
        <!-- 状态和优先级徽章 -->
        <div class="flex flex-wrap gap-2 mb-2">
          <span class="badge <%= status_badge_class(issue.status) %>">
            <%= issue.status_display %>
          </span>
          <span class="badge <%= priority_badge_class(issue.priority) %>">
            <%= issue.priority_display %>
          </span>
          
          <!-- 移动端：未读徽章 -->
          <% if issue.unread_count_for(current_user) > 0 %>
            <span class="badge badge-danger badge-sm">
              <%= issue.unread_count_for(current_user) %> 条新回复
            </span>
          <% end %>
        </div>
        
        <!-- 描述预览 - 移动端1行，桌面端2行 -->
        <p class="text-secondary line-clamp-1 md:line-clamp-2 text-sm">
          <%= truncate(issue.description, length: 100) %>
        </p>
      </div>
      
      <!-- 评论数 - 移动端右上角，桌面端右侧 -->
      <div class="flex md:flex-col items-center gap-2 self-start">
        <%= lucide_icon "message-square", class: "w-5 h-5 text-secondary" %>
        <span class="text-sm font-medium text-secondary">
          <%= issue.comments.approved.count %>
        </span>
      </div>
    </div>
    
    <!-- 移动端：滑动操作提示 -->
    <div class="md:hidden text-xs text-secondary text-center mt-2 py-1 border-t">
      ← 左滑查看更多操作
    </div>
  </div>
</div>
```

#### 8.2 移动端快捷操作
```typescript
// app/javascript/controllers/mobile_swipe_controller.ts
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "actions"]
  
  startX: number = 0
  currentX: number = 0
  
  connect() {
    if (this.isMobile()) {
      this.cardTarget.addEventListener('touchstart', this.onTouchStart.bind(this))
      this.cardTarget.addEventListener('touchmove', this.onTouchMove.bind(this))
      this.cardTarget.addEventListener('touchend', this.onTouchEnd.bind(this))
    }
  }
  
  onTouchStart(e: TouchEvent) {
    this.startX = e.touches[0].clientX
  }
  
  onTouchMove(e: TouchEvent) {
    this.currentX = e.touches[0].clientX
    const diff = this.startX - this.currentX
    
    if (diff > 0 && diff < 100) {
      // 左滑，显示操作菜单
      this.cardTarget.style.transform = `translateX(-${diff}px)`
      this.actionsTarget.style.opacity = `${diff / 100}`
    }
  }
  
  onTouchEnd() {
    const diff = this.startX - this.currentX
    
    if (diff > 50) {
      // 完全展开操作菜单
      this.cardTarget.style.transform = 'translateX(-100px)'
      this.actionsTarget.style.opacity = '1'
    } else {
      // 回弹
      this.cardTarget.style.transform = 'translateX(0)'
      this.actionsTarget.style.opacity = '0'
    }
  }
  
  isMobile(): boolean {
    return window.innerWidth < 768
  }
}
```

---

## 🚀 实施计划

### Phase 1: 核心功能（1-2周）
- ✅ 多方讨论权限
- ✅ @提醒机制
- ✅ 实时推送（ActionCable）
- ✅ 自动状态流转
- ✅ 决策结论字段

### Phase 2: 增强功能（2-3周）
- ✅ 置顶评论与关键意见
- ✅ 高级筛选与快捷标签
- ✅ 关注功能与未读提醒
- ✅ 附件分类管理
- ✅ 智能提醒任务

### Phase 3: 集成与分析（1-2周）
- ✅ 模块关联
- ✅ 待办创建
- ✅ 分享链接
- ✅ 数据统计仪表板
- ✅ 趋势分析图表

### Phase 4: 移动端与优化（1周）
- ✅ 响应式优化
- ✅ 滑动操作
- ✅ 语音输入
- ✅ 性能优化

---

## 📊 预期效果

### 用户体验提升
- ⬆️ 讨论参与度提升 **200%**（企业用户可参与）
- ⬇️ 平均响应时间缩短 **50%**（实时通知）
- ⬆️ 问题解决率提升 **30%**（智能提醒）
- ⬆️ 知识复用率提升 **80%**（决策记录）

### 工作效率提升
- ⬇️ 查找时间缩短 **70%**（高级筛选）
- ⬇️ 状态管理工作量减少 **60%**（自动流转）
- ⬆️ 协作效率提升 **40%**（模块集成）

### 管理决策支持
- 📈 实时掌握处理进度
- 📊 量化律师工作量
- 🎯 识别高风险事项
- 💡 优化资源配置

---

## ✅ 技术栈

- **后端**: Rails 7.2 + PostgreSQL
- **实时**: ActionCable + Redis（可选）
- **前端**: Stimulus + Turbo + TailwindCSS
- **图表**: Chartkick + Chart.js
- **任务**: GoodJob
- **存储**: ActiveStorage

---

## 🎯 成功指标

1. **用户采纳率** ≥ 90%（活跃律师和企业用户）
2. **平均处理时长** ≤ 5天
3. **用户满意度** ≥ 4.5/5
4. **系统稳定性** ≥ 99.5%
5. **移动端使用率** ≥ 40%
