class CasesController < ApplicationController
  before_action :require_authentication
  before_action :set_company
  before_action :set_case, only: [:show, :edit, :update, :destroy, :request_deletion, :confirm_deletion, :delete_directly, :download_archive]

  def index
    @cases = @company.cases.not_deleted.ordered.page(params[:page])
  end

  def show
    @comments = @case.comments.approved.ordered
    @work_logs = @case.work_logs.ordered
  end

  def new
    if lawyer?
      # 律师创建案件时,需要选择企业
      @companies = Company.ordered
      # 如果有 company_id 参数,使用指定的企业
      @selected_company = params[:company_id].present? ? Company.find(params[:company_id]) : @company
      @case = Case.new
    else
      # 企业用户只能为自己的企业创建案件
      @case = @company.cases.new
    end
  end

  def create
    if lawyer?
      # 律师创建案件时,必须指定 company_id
      company_id = case_params[:company_id]
      if company_id.blank?
        redirect_to new_case_path, alert: '请选择案件所属企业' and return
      end
      
      target_company = Company.find(company_id)
      @case = target_company.cases.new(case_params.except(:company_id))
    else
      # 企业用户只能为自己的企业创建案件
      @case = @company.cases.new(case_params)
    end
    
    if @case.save
      redirect_to case_path(@case), notice: '案件创建成功'
    else
      if lawyer?
        @companies = Company.ordered
        @selected_company = @case.company
      end
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @case.update(case_params)
      redirect_to case_path(@case), notice: '案件信息已更新'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @case.destroy
    redirect_to cases_path, notice: '案件已删除'
  end

  def request_deletion
    if @case.request_deletion_by_employee(current_company_user)
      redirect_to case_path(@case), notice: '删除请求已提交，等待老板确认'
    else
      redirect_to case_path(@case), alert: '删除请求失败'
    end
  end

  def confirm_deletion
    if current_company_user&.boss?
      @case.confirm_deletion_by_boss(current_company_user)
      redirect_to cases_path, notice: '案件已删除'
    else
      redirect_to case_path(@case), alert: '仅老板可以确认删除'
    end
  end

  def delete_directly
    if current_lawyer
      # 律师可以直接删除案件
      @case.destroy
      redirect_to lawyer_companies_path, notice: '案件已删除'
    elsif current_company_user&.boss?
      # 企业主老板可以直接删除案件
      @case.delete_by_boss(current_company_user)
      redirect_to cases_path, notice: '案件已删除'
    else
      redirect_to case_path(@case), alert: '仅律师和企业老板可以删除案件'
    end
  end
  
  def download_archive
    # 只有企业老板可以下载已归档案件的完整档案
    unless current_company_user && @case.can_boss_download_archive?(current_company_user)
      redirect_to case_path(@case), alert: '您没有权限下载归档档案'
      return
    end
    
    # 生成归档档案压缩包
    require 'zip'
    require 'stringio'
    
    zip_stream = Zip::OutputStream.write_buffer do |zip|
      # 添加案件基本信息文本文件
      case_info = generate_case_info_text(@case)
      zip.put_next_entry("案件信息.txt")
      zip.write case_info
      
      # 添加所有附件
      add_attachments_to_zip(zip, @case.attachments, "通用附件")
      add_attachments_to_zip(zip, @case.filing_attachments, "立案附件")
      add_attachments_to_zip(zip, @case.hearing_attachments, "开庭附件")
      add_attachments_to_zip(zip, @case.judgement_attachments, "判决书附件")
      add_attachments_to_zip(zip, @case.archived_attachments, "归档附件")
      
      # 添加工作大事记
      @case.work_logs.ordered.each_with_index do |work_log, index|
        work_log_text = "日期：#{work_log.date.strftime('%Y年%m月%d日')}\n标题：#{work_log.title}\n内容：\n#{work_log.content}"
        zip.put_next_entry("工作大事记/#{index + 1}_#{work_log.title.gsub('/', '-')}.txt")
        zip.write work_log_text
        
        # 添加工作大事记附件
        if work_log.attachments.attached?
          work_log.attachments.each do |attachment|
            zip.put_next_entry("工作大事记/#{index + 1}_#{work_log.title.gsub('/', '-')}_附件/#{attachment.filename}")
            zip.write attachment.download
          end
        end
      end
      
      # 添加律师意见
      approved_comments = @case.comments.where(review_status: 'approved').order(created_at: :desc)
      if approved_comments.any?
        approved_comments.each_with_index do |comment, index|
          comment_text = "作者：#{comment.author_name}\n时间：#{comment.created_at.strftime('%Y年%m月%d日 %H:%M')}\n内容：\n#{comment.content}"
          zip.put_next_entry("律师意见/#{index + 1}_#{comment.author_name}.txt")
          zip.write comment_text
          
          # 添加律师意见附件
          if comment.attachments.attached?
            comment.attachments.each do |attachment|
              zip.put_next_entry("律师意见/#{index + 1}_#{comment.author_name}_附件/#{attachment.filename}")
              zip.write attachment.download
            end
          end
        end
      end
    end
    
    zip_stream.rewind
    filename = "#{@case.name}_归档档案_#{Time.current.strftime('%Y%m%d')}.zip"
    send_data zip_stream.read, filename: filename, type: 'application/zip'
  end

  private

  def require_authentication
    unless current_user || current_lawyer
      redirect_to login_path, alert: '请先登录'
    end
  end

  def set_company
    @company = if current_company_user
                 # 企业主只能访问自己的公司数据,防止客户信息泄露
                 current_company_user.company
               elsif current_lawyer
                 # 律师必须先选择企业
                 if session[:viewing_company_id]
                   Company.find(session[:viewing_company_id])
                 else
                   # 如果没有选择企业，重定向到律师工作台
                   redirect_to lawyer_companies_path, alert: '请先选择企业' and return
                 end
               end
    
    redirect_to root_path, alert: '未找到公司' unless @company
  end

  def set_case
    if current_lawyer
      # 律师可以访问所有公司的案件
      @case = Case.find(params[:id])
      # 更新 @company 为该案件所属的公司
      @company = @case.company
    else
      # 企业用户只能访问自己公司的案件
      @case = @company.cases.find(params[:id])
    end
  end

  def case_params
    params.require(:case).permit(
      :company_id, :name, :case_number, :case_type, :court_name, :status, :stage,
      :filing_at, :hearing_at, :judgement_received_at, :archived_at,
      :closing_at, :summary, 
      attachments: [],
      filing_attachments: [],
      hearing_attachments: [],
      judgement_attachments: [],
      archived_attachments: []
    )
  end
  
  # 生成案件信息文本
  def generate_case_info_text(case_record)
    info = []
    info << "案件名称：#{case_record.name}"
    info << "案号：#{case_record.case_number.present? ? case_record.case_number : '待立案'}"
    info << "案件类型：#{case_record.case_type}"
    info << "法院名称：#{case_record.court_name}"
    info << "案件状态：#{case_record.status_display}"
    info << "案件阶段：#{case_record.stage_display}" if case_record.stage.present?
    info << "立案日期：#{case_record.filing_at.strftime('%Y年%m月%d日')}" if case_record.filing_at
    info << "开庭时间：#{case_record.hearing_at.strftime('%Y年%m月%d日 %H:%M')}" if case_record.hearing_at
    info << "领取判决书日期：#{case_record.judgement_received_at.strftime('%Y年%m月%d日')}" if case_record.judgement_received_at
    info << "归档日期：#{case_record.archived_at.strftime('%Y年%m月%d日')}" if case_record.archived_at
    info << "结案日期：#{case_record.closing_at.strftime('%Y年%m月%d日')}" if case_record.closing_at
    info << "\n案件摘要："
    info << case_record.summary if case_record.summary.present?
    info.join("\n")
  end
  
  # 将附件添加到ZIP文件
  def add_attachments_to_zip(zip, attachments, folder_name)
    return unless attachments.attached?
    attachments.each do |attachment|
      zip.put_next_entry("#{folder_name}/#{attachment.filename}")
      zip.write attachment.download
    end
  end
end
