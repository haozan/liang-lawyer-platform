class Admin::DataAccessLogsController < Admin::BaseController
  before_action :set_data_access_log, only: [:show]

  def index
    @data_access_logs = DataAccessLog.includes(:lawyer).page(params[:page]).per(50)
    
    # 过滤：根据资源类型
    if params[:resource_type].present?
      @data_access_logs = @data_access_logs.where(resource_type: params[:resource_type])
    end
    
    # 过滤：根据操作类型
    if params[:action_type].present?
      @data_access_logs = @data_access_logs.where(action: params[:action_type])
    end
    
    # 过滤：根据访问方式
    if params[:access_method].present?
      @data_access_logs = @data_access_logs.where(access_method: params[:access_method])
    end
    
    # 过滤：根据律师
    if params[:lawyer_id].present?
      @data_access_logs = @data_access_logs.where(lawyer_id: params[:lawyer_id])
    end
    
    # 过滤：根据日期范围
    if params[:start_date].present?
      @data_access_logs = @data_access_logs.where('created_at >= ?', params[:start_date].to_date.beginning_of_day)
    end
    
    if params[:end_date].present?
      @data_access_logs = @data_access_logs.where('created_at <= ?', params[:end_date].to_date.end_of_day)
    end
    
    @data_access_logs = @data_access_logs.order(created_at: :desc)
  end

  def show
  end

  private

  def set_data_access_log
    @data_access_log = DataAccessLog.find(params[:id])
  end
end
