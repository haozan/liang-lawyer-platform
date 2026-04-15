module ApplicationHelper
  # Smart file link that handles different file types intelligently
  # - Images: inline preview with modal
  # - PDFs: inline view in new tab
  # - Others: download in new tab
  # 
  # Options:
  #   - text: Custom link text (defaults to filename)
  #   - icon: Custom icon name (auto-detected if not provided)
  #   - css_class: Additional CSS classes
  #   - show_size: Show file size in parentheses
  #   - deletable: Show delete button (default: false)
  #   - delete_confirm: Custom delete confirmation message
  #   - action_buttons: Show action button group (preview/download + delete) (default: false)
  def smart_file_link(attachment, text: nil, icon: nil, css_class: '', show_size: false, deletable: false, delete_confirm: nil, action_buttons: false, **html_options)
    # Handle both ActiveStorage::Attachment instances and ActiveRecord models with attachments
    if attachment.is_a?(ActiveStorage::Attachment)
      # Already an attachment instance
      return content_tag(:span, text || '未上传', class: 'text-muted') if attachment.blank?
    else
      # It's an ActiveRecord model with attachment association
      return content_tag(:span, text || '未上传', class: 'text-muted') unless attachment&.attached?
      attachment = attachment.attachment
    end
    
    filename = text || attachment.filename.to_s
    content_type = attachment.content_type || ''
    file_size = number_to_human_size(attachment.byte_size) if show_size
    
    # Default icon based on file type
    icon ||= detect_file_icon(content_type)
    
    # Use action_buttons mode if requested
    if action_buttons
      return build_action_buttons_group(attachment, filename, content_type, file_size, deletable, delete_confirm, css_class)
    end
    
    # Wrapper for deletable files
    wrapper_id = "attachment_#{attachment.id}" if deletable
    wrapper_class = 'flex items-center gap-2' if deletable
    
    # Build file link
    file_link = build_file_link(attachment, filename, content_type, file_size, icon, css_class, html_options)
    
    # Add delete button if requested
    if deletable
      content_tag(:div, id: wrapper_id, class: wrapper_class) do
        concat file_link
        concat build_delete_button(attachment, filename, delete_confirm)
      end
    else
      file_link
    end
  end
  
  private
  
  # 生成安全文件访问路径（需要权限验证）
  # Options:
  #   - disposition: 'inline' or 'attachment'
  #   - full_url: return full URL instead of path (default: false)
  def secure_blob_url_for(attachment, disposition: 'inline', full_url: false)
    if attachment.is_a?(ActiveStorage::Blob)
      blob = attachment
    else
      blob = attachment.blob
    end
    
    # 根据 disposition 和 full_url 选择正确的路由 helper
    if disposition.to_s == 'attachment'
      if full_url
        secure_blob_download_url(blob.signed_id, attachment.filename)
      else
        secure_blob_download_path(blob.signed_id, attachment.filename)
      end
    else
      if full_url
        secure_blob_url(blob.signed_id, attachment.filename)
      else
        secure_blob_path(blob.signed_id, attachment.filename)
      end
    end
  end
  
  # Build the appropriate file link based on content type
  def build_file_link(attachment, filename, content_type, file_size, icon, css_class, html_options)
    if content_type.start_with?('image/')
      # Images: inline preview with modal
      link_options = html_options.merge(
        data: { 
          controller: 'image-preview',
          action: 'click->image-preview#open',
          image_preview_url_value: secure_blob_url_for(attachment, disposition: 'inline')
        },
        class: "file-link file-link-image #{css_class}"
      )
      
      link_to '#', link_options do
        concat lucide_icon(icon, class: 'w-4 h-4') if icon
        concat content_tag(:span, filename)
        concat content_tag(:span, "(#{file_size})", class: 'text-xs text-muted ml-1') if file_size
      end
    elsif content_type == 'application/pdf'
      # PDFs: open in new tab for preview
      link_options = html_options.merge(
        target: '_blank',
        rel: 'noopener noreferrer',
        data: { turbo: false },
        class: "file-link file-link-pdf #{css_class}"
      )
      
      link_to secure_blob_url_for(attachment, disposition: 'inline'), link_options do
        concat lucide_icon(icon, class: 'w-4 h-4') if icon
        concat content_tag(:span, filename)
        concat content_tag(:span, "(#{file_size})", class: 'text-xs text-muted ml-1') if file_size
      end
    else
      # Other files: download in new tab
      link_options = html_options.merge(
        target: '_blank',
        data: { turbo: false },
        class: "file-link file-link-download #{css_class}"
      )
      
      link_to secure_blob_url_for(attachment, disposition: 'attachment'), link_options do
        concat lucide_icon(icon, class: 'w-4 h-4') if icon
        concat content_tag(:span, filename)
        concat content_tag(:span, "(#{file_size})", class: 'text-xs text-muted ml-1') if file_size
        concat lucide_icon('download', class: 'w-3 h-3 ml-1') unless icon == 'download'
      end
    end
  end
  
  # Build action buttons group (preview/download + delete)
  def build_action_buttons_group(attachment, filename, content_type, file_size, deletable, delete_confirm, css_class)
    wrapper_id = "attachment_#{attachment.id}"
    
    content_tag(:div, id: wrapper_id, class: "flex flex-col gap-2 p-3 bg-surface-elevated rounded-lg #{css_class}") do
      # File info row
      file_info_row = content_tag(:div, class: 'flex items-center gap-2') do
        parts = []
        parts << lucide_icon(detect_file_icon(content_type), class: 'w-4 h-4 text-primary')
        parts << content_tag(:span, filename, class: 'text-sm font-medium text-primary flex-1')
        parts << content_tag(:span, "(#{file_size})", class: 'text-xs text-muted') if file_size
        safe_join(parts)
      end
      
      # Action buttons row
      action_buttons_row = content_tag(:div, class: 'flex items-center gap-2') do
        buttons = []
        
        # Preview button - different behavior based on file type
        buttons << build_preview_button(attachment, filename, content_type)
        
        # Download button - use secure blob path with disposition=attachment and download attribute
        download_url = secure_blob_url_for(attachment, disposition: 'attachment')
        buttons << link_to(download_url, 
          download: filename,
          target: '_blank',
          data: { turbo: false },
          class: 'btn-sm btn-success inline-flex items-center gap-1') do
          safe_join([
            lucide_icon('download', class: 'w-3 h-3'),
            content_tag(:span, '下载')
          ])
        end
        
        # Delete button
        if deletable
          buttons << build_delete_button(attachment, filename, delete_confirm)
        end
        
        safe_join(buttons)
      end
      
      safe_join([file_info_row, action_buttons_row])
    end
  end
  
  # Build preview button based on file type
  def build_preview_button(attachment, filename, content_type)
    if content_type.start_with?('image/')
      # Images: use image-preview modal
      button_tag(
        type: 'button',
        data: { 
          controller: 'image-preview',
          action: 'click->image-preview#open',
          image_preview_url_value: secure_blob_url_for(attachment, disposition: 'inline')
        },
        class: 'btn-sm btn-info inline-flex items-center gap-1') do
        safe_join([
          lucide_icon('eye', class: 'w-3 h-3'),
          content_tag(:span, '预览')
        ])
      end
    elsif content_type == 'application/pdf'
      # PDFs: use pdf-viewer modal
      button_tag(
        type: 'button',
        data: { 
          controller: 'pdf-viewer',
          action: 'click->pdf-viewer#preview',
          pdf_viewer_url_value: secure_blob_url_for(attachment, disposition: 'inline')
        },
        class: 'btn-sm btn-info inline-flex items-center gap-1') do
        safe_join([
          lucide_icon('eye', class: 'w-3 h-3'),
          content_tag(:span, '预览')
        ])
      end
    elsif content_type.match?(/word|document/)
      # Word 文档：使用 mammoth.js 在线预览（仅支持 .docx）
      button_tag(
        type: 'button',
        data: { 
          controller: 'word-viewer',
          action: 'click->word-viewer#preview',
          'word-viewer-url-value': secure_blob_url_for(attachment, disposition: 'inline')
        },
        class: 'btn-sm btn-info inline-flex items-center gap-1',
        title: '在线预览（仅支持 .docx 格式）') do
        safe_join([
          lucide_icon('eye', class: 'w-3 h-3'),
          content_tag(:span, '预览')
        ])
      end
    elsif content_type.match?(/excel|spreadsheet|powerpoint|presentation/)
      # Excel/PPT 文件：直接下载
      download_url = secure_blob_url_for(attachment, disposition: 'attachment')
      link_to(download_url, 
        data: { turbo: false },
        class: 'btn-sm btn-secondary inline-flex items-center gap-1',
        title: '下载后使用本地 Office 软件打开') do
        safe_join([
          lucide_icon('download', class: 'w-3 h-3'),
          content_tag(:span, '下载预览')
        ])
      end
    else
      # Other files: fallback to inline open in new tab
      preview_url = secure_blob_url_for(attachment, disposition: 'inline')
      link_to(preview_url, 
        target: '_blank',
        rel: 'noopener noreferrer',
        data: { turbo: false },
        class: 'btn-sm btn-info inline-flex items-center gap-1') do
        safe_join([
          lucide_icon('eye', class: 'w-3 h-3'),
          content_tag(:span, '预览')
        ])
      end
    end
  end
  
  # Build delete button for attachment
  def build_delete_button(attachment, filename, custom_message = nil)
    confirm_msg = custom_message || "确定要删除 #{filename} 吗？删除后无法恢复。"
    
    button_tag(
      type: 'button',
      class: 'btn-sm btn-danger inline-flex items-center gap-1',
      title: '删除文件',
      data: {
        controller: 'file-delete',
        action: 'click->file-delete#confirmDelete',
        'file-delete-url-value': attachment_path(attachment.id),
        'file-delete-name-value': filename
      }
    ) do
      safe_join([
        lucide_icon('trash-2', class: 'w-3 h-3'),
        content_tag(:span, '删除')
      ])
    end
  end
  
  # Create a collapsible section with automatic folding based on content count
  # 
  # Options:
  #   - title: Section title (required)
  #   - count: Number of items (auto-collapse if > threshold)
  #   - threshold: Auto-collapse threshold (default: 3)
  #   - collapsed: Force collapsed state (default: nil, auto-determine)
  #   - icon: Icon name for title (default: nil)
  #   - &block: Content block
  def collapsible_section(title:, count: 0, threshold: 3, collapsed: nil, icon: nil, &block)
    # Determine collapsed state
    should_collapse = collapsed.nil? ? (count > threshold) : collapsed
    
    # Generate unique ID for this section
    section_id = "collapsible_#{title.parameterize}_#{rand(10000)}"
    
    content_tag(:div, data: { controller: 'collapsible' }, class: 'collapsible-section') do
      concat(
        content_tag(:div, class: 'flex items-center justify-between mb-3') do
          # Title with icon and count
          title_content = content_tag(:h4, class: 'font-semibold text-primary flex items-center gap-2') do
            parts = []
            parts << lucide_icon(icon, class: 'w-4 h-4') if icon
            parts << content_tag(:span, title)
            if count > 0
              parts << content_tag(:span, "(#{count})", class: 'text-sm text-muted font-normal')
            end
            safe_join(parts)
          end
          
          # Toggle button
          toggle_button = button_tag(
            type: 'button',
            class: 'text-sm text-secondary hover:text-primary transition-colors flex items-center gap-1',
            data: { action: 'click->collapsible#toggle' }
          ) do
            safe_join([
              content_tag(:span, should_collapse ? '展开' : '收起', data: { collapsible_target: 'toggleText' }),
              lucide_icon('chevron-down', class: "w-4 h-4 transition-transform #{should_collapse ? 'rotate-180' : ''}", data: { collapsible_target: 'icon' })
            ])
          end
          
          safe_join([title_content, toggle_button])
        end
      )
      
      # Collapsible content
      concat(
        content_tag(:div, 
          data: { collapsible_target: 'content' },
          class: should_collapse ? 'hidden' : '',
          &block
        )
      )
    end
  end
  
  def detect_file_icon(content_type)
    case content_type
    when /^image\//
      'image'
    when 'application/pdf'
      'file-text'
    when /word|document/
      'file-text'
    when /excel|spreadsheet/
      'file-spreadsheet'
    when /zip|rar|7z/
      'file-archive'
    else
      'paperclip'
    end
  end
  
  # Display author role badge for comments
  def comment_author_role_badge(author_role)
    role_map = {
      'lawyer' => '律师',
      'assistant' => '助理',
      'boss' => '老板',
      'employee' => '员工',
      'hr' => 'HR'
    }
    
    role_text = role_map[author_role] || author_role
    content_tag(:span, role_text, class: 'badge badge-secondary badge-sm')
  end
  
  # 手机号脱敏：138****8000
  def mask_phone(phone)
    return '' if phone.blank?
    phone.to_s.gsub(/(\d{3})\d{4}(\d{4})/, '\1****\2')
  end
  
  # 金额脱敏（根据当前用户角色）
  # 老板和主管看完整金额，律师看完整金额，普通员工只看数量级
  def mask_amount(amount, user = current_user)
    return '' if amount.blank?
    
    # 老板和主管看完整金额
    if company_user? && current_membership&.boss?
      number_to_currency(amount, unit: '¥', precision: 2)
    elsif lawyer?
      # 律师看完整金额
      number_to_currency(amount, unit: '¥', precision: 2)
    else
      # 普通员工只看数量级
      if amount > 1_000_000
        "#{(amount / 10000).to_i}万元以上"
      elsif amount > 100_000
        "10-100万元"
      else
        "10万元以下"
      end
    end
  end
end
