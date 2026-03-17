class ContractAnalyticsController < ApplicationController
  before_action :require_authentication
  before_action :set_company
  before_action :set_date_range
  before_action :set_compare_date_range
  
  def dashboard
    # 调用分析服务
    analytics = ContractAnalyticsService.call(
      company: @company,
      lawyer: @lawyer,
      date_from: @date_from,
      date_to: @date_to,
      compare_date_from: @compare_date_from,
      compare_date_to: @compare_date_to
    )
    
    # 提取数据到实例变量供视图使用
    @core_kpis = analytics[:core_kpis]
    @risk_alerts = analytics[:risk_alerts]
    @trends = analytics[:trends]
    @distributions = analytics[:distributions]
    @amount_statistics = analytics[:amount_statistics]
    @lawyer_review_stats = analytics[:lawyer_review_stats]
    @company_rankings = analytics[:company_rankings]
    @comparison = analytics[:comparison]
    @export_data = analytics[:export_data]
    
    # 添加视图所需的变量别名
    @distributions[:risk_distribution] = @distributions[:risk_level_distribution] || {}
    @distributions[:type_distribution] = @distributions[:contract_type_distribution] || {}
    @amount_stats = @amount_statistics
    
    # 计算到期时间分布
    base_scope = analytics[:base_scope]
    @expiration_timeline = {
      '已到期' => base_scope.where('end_at < ?', Date.today).count,
      '30天内' => base_scope.where(end_at: Date.today..30.days.from_now).count,
      '31-90天' => base_scope.where(end_at: 31.days.from_now..90.days.from_now).count,
      '91-180天' => base_scope.where(end_at: 91.days.from_now..180.days.from_now).count,
      '180天以上' => base_scope.where('end_at > ?', 180.days.from_now).count
    }
    
    # 计算律师工作量
    @lawyer_workload = LawyerAccount.joins('LEFT JOIN contracts ON contracts.assigned_lawyer_id = lawyer_accounts.id')
      .where(contracts: { id: base_scope.select(:id) })
      .group('lawyer_accounts.id', 'lawyer_accounts.name')
      .select('lawyer_accounts.id, lawyer_accounts.name as lawyer_name, COUNT(contracts.id) as total_contracts')
      .order('total_contracts DESC')
      .limit(10)
      .map { |l| { lawyer_id: l.id, lawyer_name: l.lawyer_name, total_contracts: l.total_contracts } }
    
    # 用于筛选的企业列表（仅律师）
    @companies = Company.ordered if lawyer?
  end
  
  def export_report
    analytics = ContractAnalyticsService.call(
      company: @company,
      lawyer: @lawyer,
      date_from: @date_from,
      date_to: @date_to
    )
    
    require 'csv'
    
    csv_data = CSV.generate(headers: true, encoding: 'UTF-8') do |csv|
      # 标题行
      csv << ['合同数据分析报表']
      csv << []
      csv << ['生成时间', Time.current.strftime('%Y-%m-%d %H:%M:%S')]
      csv << ['数据范围', "#{@date_from} 至 #{@date_to}"]
      csv << ['企业', @company&.name || '全部企业']
      csv << []
      
      # 核心KPI
      csv << ['核心指标']
      csv << ['指标名称', '数值']
      kpis = analytics[:core_kpis]
      csv << ['合同总数', kpis[:total_contracts]]
      csv << ['执行中', kpis[:active_contracts]]
      csv << ['已完成', kpis[:completed_contracts]]
      csv << ['已违约', kpis[:breach_contracts]]
      csv << ['诉讼中', kpis[:litigation_contracts]]
      csv << ['合同总金额（元）', kpis[:total_amount]]
      csv << ['本月新签', kpis[:current_month_new]]
      csv << []
      
      # 风险预警
      csv << ['风险预警']
      csv << ['预警类型', '数量']
      alerts = analytics[:risk_alerts]
      csv << ['即将到期（30天内）', alerts[:expiring_soon]]
      csv << ['高风险合同', alerts[:high_risk]]
      csv << ['逾期未审查', alerts[:overdue_review]]
      csv << ['对账单逾期', alerts[:overdue_reconciliation]]
      csv << []
      
      # 金额统计
      csv << ['金额统计']
      csv << ['统计项', '金额（元）']
      amounts = analytics[:amount_statistics]
      csv << ['合同总金额', amounts[:total_amount]]
      csv << ['平均合同金额', amounts[:avg_amount]]
      csv << ['最大合同金额', amounts[:max_amount]]
      csv << ['最小合同金额', amounts[:min_amount]]
      csv << []
      
      # 状态分布
      csv << ['状态分布']
      csv << ['状态', '数量']
      analytics[:distributions][:status_distribution].each do |status, count|
        status_name = Contract.new(status: status).status_display
        csv << [status_name, count]
      end
      csv << []
      
      # 合同类型分布
      csv << ['合同类型分布']
      csv << ['类型', '数量']
      analytics[:distributions][:contract_type_distribution].each do |type, count|
        csv << [type, count]
      end
      csv << []
      
      # 风险等级分布
      csv << ['风险等级分布']
      csv << ['风险等级', '数量']
      analytics[:distributions][:risk_level_distribution].each do |level, count|
        csv << [level, count]
      end
      csv << []
      
      # 律师审查统计
      csv << ['律师审查统计']
      csv << ['统计项', '数值']
      review = analytics[:lawyer_review_stats]
      csv << ['合同总数', review[:total]]
      csv << ['已审查', review[:reviewed]]
      csv << ['待审查', review[:pending_review]]
      csv << ['审查完成率（%）', review[:review_rate]]
      csv << ['审查及时率（%）', review[:timeliness_rate]]
      csv << ['平均审查时长（天）', review[:avg_review_days]]
      csv << []
      
      # 企业排行
      if analytics[:company_rankings][:by_count].any?
        csv << ['企业合同数量排行（TOP 10）']
        csv << ['企业名称', '合同数量']
        analytics[:company_rankings][:by_count].each do |ranking|
          csv << [ranking[:company_name], ranking[:contracts_count]]
        end
        csv << []
        
        csv << ['企业合同金额排行（TOP 10）']
        csv << ['企业名称', '合同总金额（元）']
        analytics[:company_rankings][:by_amount].each do |ranking|
          csv << [ranking[:company_name], ranking[:total_amount]]
        end
      end
    end
    
    filename = "合同数据分析_#{@date_from}_#{@date_to}_#{Time.current.strftime('%Y%m%d%H%M%S')}.csv"
    send_data "\uFEFF#{csv_data}", filename: filename, type: 'text/csv; charset=utf-8'
  end
  
  private
  
  def require_authentication
    unless current_user || current_lawyer
      redirect_to login_path, alert: '请先登录'
    end
  end
  
  def set_company
    @company = if lawyer?
      # 律师可以选择企业或查看全部
      if params[:company_id].present? && params[:company_id] != 'all'
        Company.find(params[:company_id])
      else
        nil
      end
    else
      # 企业用户只能查看自己的企业
      # 如果尝试访问其他企业，重定向
      if params[:company_id].present? && params[:company_id].to_i != current_company_user.company_id
        redirect_to dashboard_contract_analytics_path, alert: '没有权限查看该企业数据'
        return
      end
      current_company_user.company
    end
    
    @lawyer = params[:lawyer_id].present? ? LawyerAccount.find(params[:lawyer_id]) : nil
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
