class LawyerFeeAnalyticsController < ApplicationController
  before_action :require_lawyer_authentication
  before_action :set_filters
  before_action :set_date_range
  before_action :set_compare_date_range
  
  def dashboard
    analytics = LawyerFeeAnalyticsService.call(
      company: @company,
      lawyer: @lawyer,
      date_from: @date_from,
      date_to: @date_to,
      compare_date_from: @compare_date_from,
      compare_date_to: @compare_date_to,
      payment_status: @payment_status,
      case_type: @case_type,
      case_status: @case_status,
      fee_range: @fee_range,
      invoice_status: @invoice_status,
      time_dimension: @time_dimension
    )
    
    @core_kpis = analytics[:core_kpis]
    @urgent_alerts = analytics[:urgent_alerts]
    @trends = analytics[:trends]
    @distributions = analytics[:distributions]
    @lawyer_workload = analytics[:lawyer_workload]
    @company_rankings = analytics[:company_rankings]
    @comparison = analytics[:comparison]
    
    @companies = Company.ordered if current_lawyer_account.present?
    @lawyers = LawyerAccount.where(role: ['assistant', 'lawyer', 'senior_lawyer', 'team_leader', 'super_admin']).order(:name)
    @available_case_types = Case.not_deleted.where.not(lawyer_fee: nil).distinct.pluck(:case_type).compact.sort
  end
  
  def export_detailed
    analytics = LawyerFeeAnalyticsService.call(
      company: @company,
      lawyer: @lawyer,
      date_from: @date_from,
      date_to: @date_to,
      payment_status: @payment_status,
      case_type: @case_type,
      case_status: @case_status,
      fee_range: @fee_range,
      invoice_status: @invoice_status,
      time_dimension: @time_dimension
    )
    
    require 'csv'
    
    cases = analytics[:base_scope]
    
    csv_data = CSV.generate(headers: true, encoding: 'UTF-8') do |csv|
      csv << ['律师费明细统计表']
      csv << []
      csv << ['生成时间', Time.current.strftime('%Y-%m-%d %H:%M:%S')]
      csv << ['数据范围', "#{@date_from} 至 #{@date_to}"]
      csv << ['数据总量', "#{cases.count} 条"]
      csv << []
      
      # 筛选条件说明
      csv << ['=== 筛选条件 ===']
      csv << ['企业', @company&.name || '全部企业']
      csv << ['主办律师', @lawyer&.name || '全部律师']
      csv << ['时间维度', time_dimension_display]
      
      if @payment_status.present?
        csv << ['付款状态', payment_status_display(@payment_status)]
      end
      
      if @case_type.present?
        csv << ['案件类型', @case_type]
      end
      
      if @case_status.present?
        csv << ['案件状态', case_status_display(@case_status)]
      end
      
      if @fee_range.present?
        csv << ['律师费范围', fee_range_display(@fee_range)]
      end
      
      if @invoice_status.present?
        csv << ['开票状态', invoice_status_display(@invoice_status)]
      end
      
      csv << []
      
      csv << [
        '案件ID', '案件名称', '案件编号', '案件类型', '立案日期', '结案日期',
        '案件状态', '企业客户', '主办律师', '参与律师',
        '律师费金额', '付款方式', '付款条款', '是否已开票',
        '已回款金额', '待回款金额', '回款日期', '付款状态', '回款周期(天)'
      ]
      
      cases.includes(:company, :case_team_members, :lawyer_fee_invoice_attachment).find_each do |case_record|
        lead_lawyer = case_record.case_team_members.find_by(role: 'lead_lawyer')&.lawyer_account&.name
        assistant_lawyers = case_record.case_team_members.where(role: 'assistant_lawyer').map { |m| m.lawyer_account&.name }.compact.join(', ')
        
        has_invoice = case_record.lawyer_fee_invoice.attached? ? '已开票' : '未开票'
        pending_amount = (case_record.lawyer_fee.to_f - case_record.lawyer_fee_received.to_f).round(2)
        
        collection_days = if case_record.lawyer_fee_received_at.present? && case_record.filing_at.present?
          ((case_record.lawyer_fee_received_at.to_time - case_record.filing_at.to_time) / 1.day).to_i
        else
          ''
        end
        
        payment_status_display = case case_record.lawyer_fee_payment_status
        when 'pending' then '待付款'
        when 'partial' then '部分付款'
        when 'completed' then '已付清'
        else '待付款'
        end
        
        csv << [
          case_record.id,
          case_record.name,
          case_record.case_number,
          case_record.case_type,
          case_record.filing_at&.strftime('%Y-%m-%d'),
          case_record.closing_at&.strftime('%Y-%m-%d'),
          case_record.status_display,
          case_record.company.name,
          lead_lawyer,
          assistant_lawyers,
          case_record.lawyer_fee,
          case_record.lawyer_fee_payment_terms&.split("\n")&.first || '',
          case_record.lawyer_fee_payment_terms,
          has_invoice,
          case_record.lawyer_fee_received || 0,
          pending_amount,
          case_record.lawyer_fee_received_at&.strftime('%Y-%m-%d'),
          payment_status_display,
          collection_days
        ]
      end
    end
    
    filename = generate_filename('明细表', cases.count)
    send_data "\uFEFF#{csv_data}", filename: filename, type: 'text/csv; charset=utf-8'
  end
  
  def export_lawyer_summary
    analytics = LawyerFeeAnalyticsService.call(
      company: @company,
      lawyer: @lawyer,
      date_from: @date_from,
      date_to: @date_to,
      payment_status: @payment_status,
      case_type: @case_type,
      case_status: @case_status,
      fee_range: @fee_range,
      invoice_status: @invoice_status,
      time_dimension: @time_dimension
    )
    
    require 'csv'
    
    csv_data = CSV.generate(headers: true, encoding: 'UTF-8') do |csv|
      csv << ['律师个人律师费统计表']
      csv << []
      csv << ['生成时间', Time.current.strftime('%Y-%m-%d %H:%M:%S')]
      csv << ['数据范围', "#{@date_from} 至 #{@date_to}"]
      csv << ['数据总量', "#{analytics[:lawyer_workload].size} 位律师"]
      csv << []
      
      # 筛选条件说明
      csv << ['=== 筛选条件 ===']
      csv << ['企业', @company&.name || '全部企业']
      csv << ['时间维度', time_dimension_display]
      
      if @payment_status.present?
        csv << ['付款状态', payment_status_display(@payment_status)]
      end
      
      if @case_type.present?
        csv << ['案件类型', @case_type]
      end
      
      if @case_status.present?
        csv << ['案件状态', case_status_display(@case_status)]
      end
      
      if @fee_range.present?
        csv << ['律师费范围', fee_range_display(@fee_range)]
      end
      
      if @invoice_status.present?
        csv << ['开票状态', invoice_status_display(@invoice_status)]
      end
      
      csv << []
      
      csv << [
        '律师姓名', '律师角色', '参与案件数', '主办案件数',
        '参与案件总律师费', '主办案件总律师费', '已回款律师费',
        '人均案件律师费'
      ]
      
      analytics[:lawyer_workload].each do |workload|
        role_display = case workload[:lawyer_role]
        when 'director' then '主任律师'
        when 'lawyer' then '律师'
        when 'assistant' then '律师助理'
        else workload[:lawyer_role]
        end
        
        csv << [
          workload[:lawyer_name],
          role_display,
          workload[:total_cases],
          workload[:lead_cases],
          workload[:total_fee],
          workload[:lead_fee],
          workload[:received_fee],
          workload[:avg_fee_per_case]
        ]
      end
      
      csv << []
      csv << ['合计', '', 
        analytics[:lawyer_workload].sum { |w| w[:total_cases] },
        analytics[:lawyer_workload].sum { |w| w[:lead_cases] },
        analytics[:lawyer_workload].sum { |w| w[:total_fee] }.round(2),
        analytics[:lawyer_workload].sum { |w| w[:lead_fee] }.round(2),
        analytics[:lawyer_workload].sum { |w| w[:received_fee] }.round(2),
        ''
      ]
    end
    
    filename = generate_filename('律师汇总表', analytics[:lawyer_workload].size)
    send_data "\uFEFF#{csv_data}", filename: filename, type: 'text/csv; charset=utf-8'
  end
  
  def export_company_summary
    analytics = LawyerFeeAnalyticsService.call(
      company: @company,
      lawyer: @lawyer,
      date_from: @date_from,
      date_to: @date_to,
      payment_status: @payment_status,
      case_type: @case_type,
      case_status: @case_status,
      fee_range: @fee_range,
      invoice_status: @invoice_status,
      time_dimension: @time_dimension
    )
    
    require 'csv'
    
    csv_data = CSV.generate(headers: true, encoding: 'UTF-8') do |csv|
      csv << ['企业客户律师费统计表']
      csv << []
      csv << ['生成时间', Time.current.strftime('%Y-%m-%d %H:%M:%S')]
      csv << ['数据范围', "#{@date_from} 至 #{@date_to}"]
      csv << ['数据总量', "#{analytics[:company_rankings].size} 家企业"]
      csv << []
      
      # 筛选条件说明
      csv << ['=== 筛选条件 ===']
      csv << ['时间维度', time_dimension_display]
      
      if @payment_status.present?
        csv << ['付款状态', payment_status_display(@payment_status)]
      end
      
      if @case_type.present?
        csv << ['案件类型', @case_type]
      end
      
      if @case_status.present?
        csv << ['案件状态', case_status_display(@case_status)]
      end
      
      if @fee_range.present?
        csv << ['律师费范围', fee_range_display(@fee_range)]
      end
      
      if @invoice_status.present?
        csv << ['开票状态', invoice_status_display(@invoice_status)]
      end
      
      csv << []
      
      csv << ['企业名称', '案件数量', '律师费总额']
      
      analytics[:company_rankings].each do |ranking|
        csv << [
          ranking[:company_name],
          ranking[:cases_count],
          ranking[:total_fee]
        ]
      end
      
      csv << []
      csv << ['合计',
        analytics[:company_rankings].sum { |r| r[:cases_count] },
        analytics[:company_rankings].sum { |r| r[:total_fee] }.round(2)
      ]
    end
    
    filename = generate_filename('企业汇总表', analytics[:company_rankings].size)
    send_data "\uFEFF#{csv_data}", filename: filename, type: 'text/csv; charset=utf-8'
  end
  
  private
  
  def require_lawyer_authentication
    unless current_lawyer_account
      redirect_to login_path, alert: '仅律师用户可以访问律师费数据分析'
    end
  end
  
  def set_filters
    @company = if params[:company_id].present? && params[:company_id] != 'all'
      Company.find(params[:company_id])
    else
      nil
    end
    
    @lawyer = params[:lawyer_id].present? && params[:lawyer_id] != 'all' ? LawyerAccount.find(params[:lawyer_id]) : nil
    @payment_status = params[:payment_status] if params[:payment_status].present? && params[:payment_status] != 'all'
    @case_type = params[:case_type] if params[:case_type].present? && params[:case_type] != 'all'
    @case_status = params[:case_status] if params[:case_status].present? && params[:case_status] != 'all'
    @fee_range = params[:fee_range] if params[:fee_range].present? && params[:fee_range] != 'all'
    @invoice_status = params[:invoice_status] if params[:invoice_status].present? && params[:invoice_status] != 'all'
    @time_dimension = params[:time_dimension].presence || 'filing_at'
  end
  
  def set_date_range
    @date_from = params[:date_from].present? ? params[:date_from].to_date : 30.days.ago.to_date
    @date_to = params[:date_to].present? ? params[:date_to].to_date : Date.today
  end
  
  def set_compare_date_range
    @compare_date_from = params[:compare_date_from].present? ? params[:compare_date_from].to_date : nil
    @compare_date_to = params[:compare_date_to].present? ? params[:compare_date_to].to_date : nil
  end
  
  # 生成智能文件名
  def generate_filename(report_type, data_count)
    parts = ['律师费', report_type]
    
    # 添加企业信息
    if @company.present?
      company_short_name = @company.name.truncate(10, omission: '')
      parts << company_short_name
    end
    
    # 添加律师信息
    if @lawyer.present?
      parts << @lawyer.name
    end
    
    # 添加关键筛选条件
    if @payment_status.present?
      parts << payment_status_display(@payment_status)
    end
    
    if @case_type.present?
      case_type_short = @case_type.truncate(8, omission: '')
      parts << case_type_short
    end
    
    # 添加日期范围
    date_range = "#{@date_from}_#{@date_to}"
    parts << date_range
    
    # 添加数据量（如果有意义）
    if data_count > 0 && data_count < 10000
      parts << "#{data_count}条"
    end
    
    # 添加时间戳
    timestamp = Time.current.strftime('%H%M%S')
    
    # 组合文件名（限制总长度）
    filename = parts.join('_')
    filename = filename.truncate(80, omission: '')
    "#{filename}_#{timestamp}.csv"
  end
  
  # 显示辅助方法
  def time_dimension_display
    {
      'filing_at' => '立案日期',
      'received_at' => '回款日期',
      'invoice_at' => '开票日期',
      'closing_at' => '结案日期'
    }[@time_dimension] || '立案日期'
  end
  
  def payment_status_display(status)
    {
      'pending' => '待付款',
      'partial' => '部分付款',
      'completed' => '已付清'
    }[status] || status
  end
  
  def case_status_display(status)
    {
      'preparing' => '准备立案',
      'filed' => '已立案待审',
      'trial' => '审理中',
      'judged' => '已判决',
      'execution' => '执行中',
      'settled' => '调解结案',
      'closed' => '已归档'
    }[status] || status
  end
  
  def fee_range_display(range)
    {
      '0-50000' => '0-5万',
      '50000-100000' => '5-10万',
      '100000-200000' => '10-20万',
      '200000-500000' => '20-50万',
      '500000-0' => '50万以上'
    }[range] || range
  end
  
  def invoice_status_display(status)
    {
      'issued' => '已开票',
      'not_issued' => '未开票'
    }[status] || status
  end
end
