class WorkLogsController < ApplicationController
  before_action :require_authentication
  before_action :set_case
  before_action :require_work_log_permission
  before_action :set_work_log, only: [:destroy, :append_attachments]

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
  
  def append_attachments
    if params[:work_log] && params[:work_log][:attachments].present?
      success_count = 0
      error_messages = []
      
      params[:work_log][:attachments].each do |attachment|
        next if attachment.blank?
        
        begin
          @work_log.attachments.attach(attachment)
          
          # 检查验证错误
          if @work_log.errors[:attachments].any?
            error_messages << @work_log.errors[:attachments].last
            @work_log.errors.delete(:attachments)
            # 移除刚才附加的无效附件
            @work_log.attachments.last.purge if @work_log.attachments.attached?
          else
            success_count += 1
          end
        rescue => e
          error_messages << "文件 #{attachment.original_filename} 上传失败：#{e.message}"
        end
      end
      
      # 根据结果返回不同消息
      if success_count > 0 && error_messages.empty?
        redirect_to case_path(@case), notice: "工作记录附件已添加（共 #{success_count} 个文件）"
      elsif success_count > 0 && error_messages.any?
        redirect_to case_path(@case), alert: "部分文件上传成功（#{success_count} 个），但有错误：#{error_messages.join('; ')}"
      elsif error_messages.any?
        redirect_to case_path(@case), alert: "上传失败：#{error_messages.join('; ')}"
      else
        redirect_to case_path(@case), alert: '请选择要上传的文件'
      end
    else
      redirect_to case_path(@case), alert: '请选择要上传的文件'
    end
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
