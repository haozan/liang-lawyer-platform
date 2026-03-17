# 配色方案快速参考卡片

> 方案一：专业法律风格 | 最后更新：2026-03-11

---

## 🎨 按钮配色速查表

```
┌─────────────────────────────────────────────────────────────────┐
│                     操作类型 → 颜色映射                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  🔵 深蓝色 (Primary)    →  创建 / 提交 / 新建                   │
│     btn-primary                                                 │
│     HSL: 210 70% 45%        HEX: #2A76C6                       │
│                                                                 │
│  🟦 青蓝色 (Info)       →  查看 / 详情 / 导出                   │
│     text-info / btn-info                                        │
│     HSL: 200 85% 45%        HEX: #0BA5D9                       │
│                                                                 │
│  🟢 森林绿 (Success)    →  批准 / 成功 / 下载完整档案           │
│     btn-success                                                 │
│     HSL: 145 70% 42%        HEX: #20A558                       │
│                                                                 │
│  🟠 琥珀色 (Warning)    →  编辑 / 修改 / 更新                   │
│     btn-warning / text-warning                                  │
│     HSL: 35 90% 55%         HEX: #F39C12                       │
│                                                                 │
│  🔴 深红色 (Danger)     →  删除 / 危险操作                      │
│     btn-danger / text-danger                                    │
│     HSL: 0 75% 55%          HEX: #E74C3C                       │
│                                                                 │
│  ⚪ 中性灰 (Secondary)  →  返回 / 取消 / 次要操作               │
│     btn-outline / btn-ghost                                     │
│     HSL: 220 15% 50%        HEX: #6D7A8C                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📦 常用代码片段

### 列表页操作列（图标链接）

```erb
<!-- 查看详情 - 青蓝色 -->
<%= link_to record_path(record), 
    class: "text-info hover:opacity-80 transition-opacity", 
    title: "查看详情" do %>
  <%= lucide_icon "eye", class: "w-4 h-4" %>
<% end %>

<!-- 编辑 - 琥珀色 -->
<%= link_to edit_record_path(record), 
    class: "text-warning hover:opacity-80 transition-opacity", 
    title: "编辑档案" do %>
  <%= lucide_icon "edit", class: "w-4 h-4" %>
<% end %>

<!-- 删除 - 深红色 -->
<%= link_to record_path(record), 
    data: { turbo_method: :delete, turbo_confirm: "确定删除吗？" }, 
    class: "text-danger hover:opacity-80 transition-opacity", 
    title: "删除档案" do %>
  <%= lucide_icon "trash-2", class: "w-4 h-4" %>
<% end %>
```

### 详情页快捷操作卡片

```erb
<div class="card card-elevated">
  <div class="card-body">
    <h3 class="font-heading text-lg font-bold text-primary mb-4">快捷操作</h3>
    <div class="space-y-2">
      <!-- 下载完整档案 - 绿色 -->
      <%= link_to export_path(@record), class: "btn-success w-full justify-start" do %>
        <%= lucide_icon "download", class: "w-4 h-4 mr-2" %>
        <span>下载完整档案</span>
      <% end %>
      
      <!-- 编辑档案 - 琥珀色 -->
      <%= link_to edit_path(@record), class: "btn-warning w-full justify-start" do %>
        <%= lucide_icon "edit", class: "w-4 h-4 mr-2" %>
        <span>编辑档案</span>
      <% end %>
      
      <!-- 删除档案 - 红色 -->
      <%= link_to path(@record), 
          data: { turbo_method: :delete, turbo_confirm: "确定删除吗？此操作不可恢复。" },
          class: "btn-danger w-full justify-start" do %>
        <%= lucide_icon "trash-2", class: "w-4 h-4 mr-2" %>
        <span>删除档案</span>
      <% end %>
    </div>
  </div>
</div>
```

### 列表页头部操作

```erb
<div class="flex items-center justify-between mb-8">
  <div>
    <h1 class="font-heading text-4xl font-bold text-primary mb-2">页面标题</h1>
    <p class="text-secondary">页面描述</p>
  </div>
  
  <!-- 新建按钮 - 深蓝色 -->
  <%= link_to new_path, class: "btn-primary" do %>
    <%= lucide_icon "plus", class: "w-5 h-5" %>
    <span>新建</span>
  <% end %>
</div>
```

### 表单提交按钮

```erb
<div class="flex gap-3 justify-end">
  <!-- 取消按钮 - 中性灰 -->
  <%= link_to "取消", back_path, class: "btn-ghost" %>
  
  <!-- 提交按钮 - 深蓝色 -->
  <%= form.submit "提交", class: "btn-primary" %>
</div>
```

---

## 🚦 决策流程图

```
需要添加按钮/链接？
    │
    ├─ 是主要操作（创建/提交）？
    │       YES → btn-primary (深蓝)
    │       NO ↓
    │
    ├─ 是查看/导出信息？
    │       YES → text-info / btn-info (青蓝)
    │       NO ↓
    │
    ├─ 是成功/批准/下载档案？
    │       YES → btn-success (绿色)
    │       NO ↓
    │
    ├─ 是编辑/修改？
    │       YES → btn-warning / text-warning (琥珀)
    │       NO ↓
    │
    ├─ 是删除/危险操作？
    │       YES → btn-danger / text-danger (红色)
    │       NO ↓
    │
    └─ 是次要操作（返回/取消）？
            YES → btn-outline / btn-ghost (灰色)
```

---

## ⚡ 常见错误

### ❌ 错误示例

```erb
<!-- 错误：编辑操作用了主色 -->
<%= link_to edit_path, class: "text-primary" do %>
  <%= lucide_icon "edit" %>
<% end %>

<!-- 错误：删除操作用了次要色 -->
<%= link_to path, class: "btn-outline" do %>
  删除
<% end %>

<!-- 错误：使用未定义的颜色类 -->
<%= link_to path, class: "text-orange-500" do %>
  编辑
<% end %>
```

### ✅ 正确示例

```erb
<!-- 正确：编辑操作用琥珀色 -->
<%= link_to edit_path, class: "text-warning hover:opacity-80" do %>
  <%= lucide_icon "edit" %>
<% end %>

<!-- 正确：删除操作用红色并添加确认 -->
<%= link_to path, 
    data: { turbo_method: :delete, turbo_confirm: "确定删除吗？" },
    class: "btn-danger" do %>
  删除
<% end %>

<!-- 正确：使用设计系统定义的颜色 -->
<%= link_to edit_path, class: "text-warning hover:opacity-80" do %>
  编辑
<% end %>
```

---

## 🎯 场景检查清单

### 新建列表页时

- [ ] 头部"新建"按钮使用 `btn-primary`（深蓝）
- [ ] 操作列"查看"图标使用 `text-info`（青蓝）
- [ ] 操作列"编辑"图标使用 `text-warning`（琥珀）
- [ ] 操作列"删除"图标使用 `text-danger`（红色）
- [ ] 所有图标链接添加 `hover:opacity-80` 效果
- [ ] 所有操作图标添加 `title` 属性

### 新建详情页时

- [ ] 快捷操作卡片标题使用 `text-primary`
- [ ] "下载完整档案"按钮使用 `btn-success`（绿色）
- [ ] "编辑档案"按钮使用 `btn-warning`（琥珀）
- [ ] "删除档案"按钮使用 `btn-danger`（红色）
- [ ] 所有按钮使用 `w-full justify-start` 保持一致布局
- [ ] 删除按钮添加 `turbo_confirm` 确认对话框

### 新建表单页时

- [ ] "提交"按钮使用 `btn-primary`（深蓝）
- [ ] "取消"按钮使用 `btn-ghost`（灰色）
- [ ] 按钮排列：取消在左，提交在右
- [ ] 必填字段使用 `form-label` + `required` 样式

---

## 📱 响应式建议

### 移动端适配

```erb
<!-- 桌面端显示完整按钮 -->
<div class="hidden md:flex gap-3">
  <%= link_to new_path, class: "btn-primary" do %>
    <%= lucide_icon "plus", class: "w-5 h-5" %>
    <span>新建合同</span>
  <% end %>
</div>

<!-- 移动端只显示图标 -->
<div class="md:hidden">
  <%= link_to new_path, class: "btn-primary", title: "新建合同" do %>
    <%= lucide_icon "plus", class: "w-5 h-5" %>
  <% end %>
</div>
```

---

## 🔗 相关文档

- 📄 [完整配色方案文档](./color_scheme_professional.md)
- 🎨 [设计系统变量](../app/assets/stylesheets/application.css)
- 🧩 [组件库文档](../app/assets/stylesheets/components.css)

---

**最后更新**：2026-03-11  
**维护者**：开发团队  
**版本**：1.0.0
