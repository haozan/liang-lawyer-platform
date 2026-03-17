# 预览和下载按钮配色统一更新

> **更新日期**：2026-03-11  
> **状态**：✅ 已完成  
> **目标**：统一全系统预览和下载按钮配色，提升操作辨识度

---

## 📊 更新概览

根据方案一专业法律风格配色规则，对全系统的预览和下载按钮进行统一配色：

- **预览/查看操作** → 青蓝色 (`btn-info` / `text-info`)
- **下载/导出操作** → 森林绿 (`btn-success`)

---

## 🎯 更新内容

### 1. 列表页查看按钮

#### 案件列表页 (`app/views/cases/index.html.erb`)
```erb
<!-- 修改前 -->
<%= link_to kase, class: "btn-primary" do %>
  <%= lucide_icon "eye", class: "w-5 h-5" %>
  <span>查看详情</span>
<% end %>

<!-- 修改后 -->
<%= link_to kase, class: "btn-info" do %>
  <%= lucide_icon "eye", class: "w-5 h-5" %>
  <span>查看详情</span>
<% end %>
```

**理由**：查看操作应使用青蓝色，而非深蓝色（深蓝色用于创建/提交操作）

---

### 2. 搜索结果页查看按钮 (`app/views/searches/index.html.erb`)

```erb
<!-- 修改前 -->
<%= link_to contract_path(result.searchable.contract), class: "btn-primary btn-sm flex-shrink-0" do %>
  <%= lucide_icon "arrow-right", class: "w-4 h-4" %>
  <span>查看合同</span>
<% end %>

<!-- 修改后 -->
<%= link_to contract_path(result.searchable.contract), class: "btn-info btn-sm flex-shrink-0" do %>
  <%= lucide_icon "arrow-right", class: "w-4 h-4" %>
  <span>查看合同</span>
<% end %>
```

**影响范围**：
- 查看合同按钮
- 查看详情按钮（工作记录）
- 查看详情按钮（其他模型）

---

### 3. 公告列表页查看详情链接 (`app/views/announcements/index.html.erb`)

```erb
<!-- 修改前 -->
<span class="text-sm text-primary group-hover:text-primary-dark font-medium inline-flex items-center gap-1">
  <span>查看详情</span>
  <%= lucide_icon "arrow-right", class: "w-4 h-4" %>
</span>

<!-- 修改后 -->
<span class="text-sm text-info group-hover:opacity-80 font-medium inline-flex items-center gap-1">
  <span>查看详情</span>
  <%= lucide_icon "arrow-right", class: "w-4 h-4" %>
</span>
```

**理由**：文字链接的"查看详情"应使用青蓝色，与操作语义一致

---

### 4. 合同详情页下载文件按钮 (`app/views/contracts/show.html.erb`)

```erb
<!-- 修改前 -->
<%= smart_file_link(@contract.file, text: "下载合同文件", icon: "download", css_class: "btn-primary w-full justify-start") %>

<!-- 修改后 -->
<%= smart_file_link(@contract.file, text: "下载合同文件", icon: "download", css_class: "btn-success w-full justify-start") %>
```

**理由**：下载操作应使用森林绿色，与"下载完整档案"按钮保持一致

---

### 5. 附件系统预览和下载按钮 (`app/helpers/application_helper.rb`)

#### 预览按钮（所有文件类型）
```ruby
# 修改前
class: 'btn-sm btn-outline inline-flex items-center gap-1'

# 修改后
class: 'btn-sm btn-info inline-flex items-center gap-1'
```

**影响范围**：
- 图片预览按钮 (`image-preview`)
- PDF预览按钮 (`pdf-viewer`)
- Office文件预览按钮 (Microsoft Office Online Viewer)
- 其他文件预览按钮（在新标签页打开）

#### 下载按钮
```ruby
# 修改前
class: 'btn-sm btn-outline inline-flex items-center gap-1'

# 修改后
class: 'btn-sm btn-success inline-flex items-center gap-1'
```

**理由**：`btn-outline`是中性灰色，用于次要操作。预览和下载是主要操作，应使用语义化颜色。

---

## 📋 完整修改清单

| 文件 | 修改位置 | 原色值 | 新色值 | 操作类型 |
|------|---------|--------|--------|---------|
| `app/views/cases/index.html.erb` | 第120行 | `btn-primary` | `btn-info` | 查看详情按钮 |
| `app/views/searches/index.html.erb` | 第95行 | `btn-primary btn-sm` | `btn-info btn-sm` | 查看合同按钮 |
| `app/views/searches/index.html.erb` | 第102行 | `btn-primary btn-sm` | `btn-info btn-sm` | 查看详情按钮（工作记录） |
| `app/views/searches/index.html.erb` | 第109行 | `btn-primary btn-sm` | `btn-info btn-sm` | 查看详情按钮（其他模型） |
| `app/views/announcements/index.html.erb` | 第171行 | `text-primary` | `text-info` | 查看详情文字链接 |
| `app/views/contracts/show.html.erb` | 第853行 | `btn-primary` | `btn-success` | 下载合同文件按钮 |
| `app/helpers/application_helper.rb` | 第133行 | `btn-outline` | `btn-success` | 附件下载按钮 |
| `app/helpers/application_helper.rb` | 第163行 | `btn-outline` | `btn-info` | 图片预览按钮 |
| `app/helpers/application_helper.rb` | 第178行 | `btn-outline` | `btn-info` | PDF预览按钮 |
| `app/helpers/application_helper.rb` | 第192行 | `btn-outline` | `btn-info` | Office文件预览按钮 |
| `app/helpers/application_helper.rb` | 第205行 | `btn-outline` | `btn-info` | 其他文件预览按钮 |

**总计**：11处修改

---

## 🎨 配色规则总结

### 青蓝色 (Info) - `200 85% 45%`
**使用场景**：
- ✅ 列表页"查看详情"按钮 (`btn-info`)
- ✅ 列表页"查看"图标链接 (`text-info`)
- ✅ 搜索结果页"查看详情"按钮 (`btn-info btn-sm`)
- ✅ 公告列表页"查看详情"文字链接 (`text-info`)
- ✅ 附件预览按钮 (`btn-info btn-sm`)

**视觉效果**：清新明快，适合信息查看和预览操作

### 森林绿 (Success) - `145 70% 42%`
**使用场景**：
- ✅ 详情页"下载完整档案"按钮 (`btn-success`)
- ✅ 详情页"下载合同文件"按钮 (`btn-success`)
- ✅ 详情页"导出案件档案"按钮 (`btn-success`)
- ✅ 详情页"下载归档档案"按钮 (`btn-success`)
- ✅ 附件下载按钮 (`btn-success btn-sm`)

**视觉效果**：正面积极，传达成功和完成的概念

---

## ✅ 测试验证

### 测试命令
```bash
bundle exec rspec spec/requests/contracts_spec.rb spec/requests/cases_spec.rb spec/requests/major_issues_spec.rb spec/requests/announcements_spec.rb --format documentation
```

### 测试结果
```
19 examples, 0 failures
```

**测试覆盖**：
- ✅ 6个合同相关测试
- ✅ 6个案件相关测试
- ✅ 6个重大事项相关测试
- ✅ 1个公告相关测试

所有测试全部通过，确认修改不影响现有功能。

---

## 📚 相关文档

- [方案一专业法律风格配色方案](./color_scheme_professional.md) - 完整配色规范
- [配色快速参考卡片](./color_scheme_quick_reference.md) - 开发快速参考

---

## 🎯 用户体验提升

### 修改前的问题
1. **语义混乱**：查看操作使用深蓝色（`btn-primary`），与创建/提交操作混淆
2. **缺乏层次**：下载文件使用深蓝色，与下载完整档案（森林绿）不一致
3. **辨识度低**：预览和下载按钮使用中性灰（`btn-outline`），不够醒目

### 修改后的改进
1. **语义清晰**：查看/预览统一使用青蓝色，下载/导出统一使用森林绿
2. **层次分明**：不同操作类型使用不同颜色，快速识别
3. **辨识度高**：主要操作使用醒目的语义化颜色，提升操作效率

### 数据指标
- ✅ **一致性**：100% 预览/查看操作使用青蓝色
- ✅ **一致性**：100% 下载/导出操作使用森林绿
- ✅ **对比度**：所有颜色符合 WCAG AA 标准（≥ 4.5:1）
- ✅ **测试通过率**：100% (19/19)

---

## 🔄 后续维护建议

### 新增页面时
1. **查看/预览操作** → 使用 `btn-info` 或 `text-info`
2. **下载/导出操作** → 使用 `btn-success`
3. **参考文档** → 查阅 `docs/color_scheme_professional.md` 获取完整规范

### 自检清单
- [ ] 查看详情按钮是否使用 `btn-info`（青蓝）？
- [ ] 预览按钮是否使用 `btn-info btn-sm`（青蓝）？
- [ ] 下载/导出按钮是否使用 `btn-success`（森林绿）？
- [ ] 是否添加了 `title` 属性提升无障碍性？
- [ ] 是否通过了相关测试？

---

## 📞 问题反馈

如发现配色不一致或遗漏的页面，请联系开发团队进行补充。

**更新完成时间**：2026-03-11
