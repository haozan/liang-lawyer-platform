class CaseAnalyticsController < ApplicationController
  include CompanyResolvable

  before_action :require_authentication
  before_action :set_company
  before_action :set_date_range
  before_action :set_compare_date_range
  
  def dashboard
    # 调用分析服务
    analytics = CaseAnalyticsService.call(
      company: @company,
      lawyer: @lawyer,
      date_from: @date_from,
      date_to: @date_to,
      compare_date_from: @compare_date_from,
      compare_date_to: @compare_date_to
    )
    
    # 提取数据到实例变量供视图使用
    @core_kpis = analytics[:core_kpis]
    @urgent_alerts = analytics[:urgent_alerts]
    @trends = analytics[:trends]
    @distributions = analytics[:distributions]
    @team_workload = analytics[:team_workload]
    @company_rankings = analytics[:company_rankings]
    @key_milestones = analytics[:key_milestones]
    @comparison = analytics[:comparison]
    @export_data = analytics[:export_data]
    
    # 用于筛选的企业列表（仅律师）
    @companies = Company.accessible_by_lawyer(current_lawyer).ordered if lawyer?
  end
  
  def export_report
    analytics = CaseAnalyticsService.call(
      company: @company,
      lawyer: @lawyer,
      date_from: @date_from,
      date_to: @date_to
    )
    
    require 'csv'
    
    csv_data = CSV.generate(headers: true, encoding: 'UTF-8') do |csv|
      # 标题行
      csv << ['案件数据分析报表']
      csv << []
      csv << ['生成时间', Time.current.strftime('%Y-%m-%d %H:%M:%S')]
      csv << ['数据范围', "#{@date_from} 至 #{@date_to}"]
      csv << ['企业', @company&.name || '全部企业']
      csv << []
      
      # 核心KPI
      csv << ['核心指标']
      csv << ['指标名称', '数值']
      kpis = analytics[:core_kpis]
      csv << ['案件总数', kpis[:total_cases]]
      csv << ['活跃案件', kpis[:active_cases]]
      csv << ['已结案', kpis[:closed_cases]]
      csv << ['待立案', kpis[:pending_cases]]
      csv << ['平均处理时长（天）', kpis[:avg_duration_days]]
      csv << ['完成率（%）', kpis[:completion_rate]]
      csv << ['本月新增', kpis[:current_month_new]]
      csv << []
      
      # 紧急预警
      csv << ['紧急预警']
      csv << ['预警类型', '数量']
      alerts = analytics[:urgent_alerts]
      csv << ['逾期开庭', alerts[:overdue_hearings]]
      csv << ['逾期判决书领取', alerts[:overdue_judgements]]
      csv << ['高优先级待处理', alerts[:urgent_pending]]
      csv << []
      
      # 状态分布
      csv << ['状态分布']
      csv << ['状态', '数量']
      analytics[:distributions][:status_distribution].each do |status, count|
        status_name = Case.new(status: status).status_display
        csv << [status_name, count]
      end
      csv << []
      
      # 阶段分布
      csv << ['阶段分布']
      csv << ['阶段', '数量']
      analytics[:distributions][:stage_distribution].each do |stage, count|
        stage_name = Case.new(stage: stage).stage_display
        csv << [stage_name, count]
      end
      csv << []
      
      # 案件类型分布
      csv << ['案件类型分布（TOP 10）']
      csv << ['类型', '数量']
      analytics[:distributions][:case_type_distribution].each do |type, count|
        csv << [type, count]
      end
      csv << []
      
      # 诉讼地位分布
      csv << ['诉讼地位分布']
      csv << ['诉讼地位', '数量']
      analytics[:distributions][:party_role_distribution].each do |role, count|
        csv << [Case::PARTY_ROLES[role] || role, count]
      end
      csv << []
      
      # 团队工作量
      if analytics[:team_workload].any?
        csv << ['团队工作量统计']
        csv << ['律师姓名', '参与案件数', '主办案件数', '活跃案件数']
        analytics[:team_workload].each do |workload|
          csv << [
            workload[:lawyer_name],
            workload[:total_cases],
            workload[:lead_cases],
            workload[:active_cases]
          ]
        end
        csv << []
      end
      
      # 企业排行
      if analytics[:company_rankings].any?
        csv << ['企业案件数排行（TOP 10）']
        csv << ['企业名称', '案件数量']
        analytics[:company_rankings].each do |ranking|
          csv << [ranking[:company_name], ranking[:cases_count]]
        end
      end
    end
    
    filename = "案件数据分析_#{@date_from}_#{@date_to}_#{Time.current.strftime('%Y%m%d%H%M%S')}.csv"
    send_data "\uFEFF#{csv_data}", filename: filename, type: 'text/csv; charset=utf-8'
  end
  
  private
  
  def require_authentication
    unless current_user || current_lawyer
      redirect_to login_path, alert: '请先登录'
    end
  end
  
  def set_company
    set_company_for_analytics(redirect_path: dashboard_case_analytics_path)
  end
  
  def set_date_range
    @date_from = params[:date_from].present? ? params[:date_from].to_date : 30.days.ago.to_date
    @date_to = params[:date_to].present? ? params[:date_to].to_date : Date.today
  end
  
  def set_compare_date_range
    @compare_date_from = params[:compare_date_from].present? ? params[:compare_date_from].to_date : nil
    @compare_date_to = params[:compare_date_to].present? ? params[:compare_date_to].to_date : nil
  end
end
