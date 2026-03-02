class WorkLogsController < ApplicationController
  before_action :require_authentication
  before_action :set_case
  before_action :require_work_log_permission
  before_action :set_work_log, only: [:destroy]

  def create
    @work_log = @case.work_logs.new(work_log_params)
    
    # 自动记录提交者
    if current_lawyer
      @work_log.submitter = current_lawyer
    elsif current_company_user
      @work_log.submitter = current_company_user
    end
    
    if @work_log.save
      redirect_to case_path(@case), notice: '工作大事记已添加'
    else
      redirect_to case_path(@case), alert: "添加失败：#{@work_log.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @work_log.destroy
    redirect_to case_path(@case), notice: '工作大事记已删除'
  end

  private

  def require_authentication
    unless current_user || current_lawyer
      redirect_to login_path, alert: '请先登录'
    end
  end

  def require_work_log_permission
    # 律师和企业用户（员工、老板）都可以操作工作大事记
    return if current_lawyer
    return if current_company_user && @case.can_company_user_edit_work_logs?(current_company_user)
    
    redirect_to root_path, alert: '您没有权限操作工作大事记'
  end

  def set_case
    @case = Case.find(params[:case_id])
  end

  def set_work_log
    @work_log = @case.work_logs.find(params[:id])
  end

  def work_log_params
    params.require(:work_log).permit(:date, :title, :content, attachments: [])
  end
end
