class EmployeePdfGeneratorService < ApplicationService
  def initialize(employee)
    @employee = employee
  end

  def call
    Prawn::Document.new(page_size: 'A4', margin: 50) do |pdf|
      # Configure Chinese font if available
      font_path = PrawnChineseFont.font_path
      use_custom_font = false
      
      if font_path && File.exist?(font_path)
        begin
          pdf.font_families.update("NotoSans" => {
            normal: font_path
          })
          pdf.font "NotoSans"
          use_custom_font = true
        rescue => e
          # If font loading fails, fall back to default font
          use_custom_font = false
        end
      end
      
      # Title
      pdf.font_size 24
      if use_custom_font
        pdf.text "员工档案", align: :center
      else
        pdf.text "员工档案", align: :center, style: :bold
      end
      pdf.move_down 10
      
      pdf.font_size 12
      pdf.text "#{@employee.company.name}", align: :center
      pdf.move_down 20
      
      # Employee Information Table
      pdf.font_size 10
      
      data = [
        ["姓名", @employee.name, "性别", @employee.gender],
        ["身份证号", @employee.id_number, "岗位", @employee.position],
        ["薪资", "¥#{@employee.salary} /月", "入职日期", format_date(@employee.hired_at)],
        ["试用期截止日", format_date(@employee.probation_end_at) || "无", "社保购买时间", format_date(@employee.social_insurance_at) || "未购买"],
        ["劳动合同签订日期", format_date(@employee.contract_signed_at), "劳动合同截止日期", format_date_with_status(@employee.contract_end_at)]
      ]
      
      pdf.table(data, width: pdf.bounds.width, cell_style: { padding: 10, borders: [:bottom], border_color: 'DDDDDD' }) do
        columns(0).width = 120
        columns(2).width = 120
      end
      
      pdf.move_down 30
      
      # Comments Section
      if @employee.comments.any?
        pdf.font_size 14
        pdf.text "评论记录"
        pdf.move_down 10
        
        @employee.comments.ordered.each do |comment|
          pdf.font_size 10
          pdf.text "#{comment.author_name} - #{comment.created_at.strftime('%Y-%m-%d %H:%M')}"
          pdf.move_down 5
          pdf.text comment.content
          
          if comment.attachments.attached?
            pdf.move_down 3
            pdf.text "附件: #{comment.attachments.map(&:filename).join(', ')}", size: 9, color: '666666'
          end
          
          pdf.move_down 10
        end
      end
      
      # Footer
      pdf.move_down 20
      pdf.font_size 8
      pdf.text "生成时间: #{Time.current.strftime('%Y年%m月%d日 %H:%M')}", align: :right, color: '999999'
    end
  end
  
  private
  
  def format_date(date)
    date&.strftime('%Y年%m月%d日')
  end
  
  def format_date_with_status(date)
    return '' unless date
    
    status = if @employee.contract_expired?
      " (已过期)"
    elsif @employee.contract_expiring_soon?
      " (即将到期)"
    else
      ""
    end
    
    "#{format_date(date)}#{status}"
  end
end
