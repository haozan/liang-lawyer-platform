class CasesController < ApplicationController
  include TeamAuthorizationConcern
  
  before_action :require_authentication
  before_action :set_company
  before_action :set_case, only: [:show, :edit, :update, :destroy, :request_deletion, :confirm_deletion, :delete_directly, :download_archive, :export_all_materials, :append_attachments, :update_property_preservation, :add_relation, :remove_relation, :update_lawyer_fee]
  before_action :check_team_access, only: [:show, :edit, :update, :destroy, :download_archive, :export_all_materials, :append_attachments, :update_property_preservation, :add_relation, :remove_relation, :update_lawyer_fee]
  before_action :check_edit_permission, only: [:update, :append_attachments, :update_property_preservation, :add_relation, :remove_relation, :update_lawyer_fee]
  before_action :check_delete_permission, only: [:destroy]

  def index
    @filter_params = filter_params
    
    # 加载保存的筛选条件
    if current_user
      @saved_filters = CaseFilter.where(user: current_user).ordered
    end
    
    # 应用筛选（使用团队权限过滤）
    base_scope = if lawyer?
      Case.accessible_by(current_lawyer_account).not_deleted
    elsif @company
      @company.cases.not_deleted
    else
      Case.not_deleted
    end
    
    @cases = base_scope.includes(:company, :case_team_members).apply_filters(@filter_params).page(params[:page]).per(20)
    
    # 统计数据
    @stats = calculate_stats(base_scope)
    
    # 快速筛选选项
    @filter_options = {
      companies: Company.ordered.pluck(:name, :id),
      team_members: LawyerAccount.ordered.pluck(:name, :id),
      statuses: %w[preparing filed trial judged execution settled closed],
      stages: %w[arbitration first_trial second_trial execution retrial resume_execution],
      case_types: Case.not_deleted.distinct.pluck(:case_type).compact,
      priorities: Case::PRIORITIES.keys
    }
  end
  
  # 案件关键日期日历视图
  def calendar
    @year = params[:year]&.to_i || Date.today.year
    @month = params[:month]&.to_i || Date.today.month
    @current_date = Date.new(@year, @month, 1)
    
    # 事件类型筛选（默认显示所有类型）
    @event_types = params[:event_types] || ['立案日期', '开庭时间', '判决领取', '归档日期', '保全到期', '执行到期']
    @status_filter = params[:status]
    
    # 获取案件范围（使用团队权限过滤）
    if lawyer?
      @cases = Case.accessible_by(current_lawyer_account).not_deleted
    elsif @company
      @cases = @company.cases.not_deleted
    else
      @cases = Case.not_deleted
    end
    
    @cases = @cases.where(status: @status_filter) if @status_filter.present?
    
    # 收集所有案件的关键日期事件
    @calendar_events = collect_calendar_events(@cases, @event_types)
    @events_by_date = @calendar_events.group_by { |event| event[:date].to_date }
  end

  def show
    @comments = @case.comments.approved.ordered
    @work_logs = @case.work_logs.ordered
    
    # 设置用户模式（律师模式 vs 企业模式）
    @user_mode = lawyer? ? :lawyer : :company
    
    # 计算律师待办事项（仅律师模式）
    @pending_tasks = lawyer? ? calculate_pending_tasks_for_case(@case) : []
  end
  
  def my_cases
    unless current_lawyer
      redirect_to cases_path, alert: '只有律师可以查看我的案件'
      return
    end
    
    @filter_params = filter_params
    @cases = Case.accessible_by(current_lawyer_account)
                  .not_deleted
                  .filter_by_team_member(current_lawyer.id)
                  .includes(:company, :case_team_members)
                  .apply_filters(@filter_params)
                  .page(params[:page]).per(20)
    
    @stats = calculate_stats(Case.accessible_by(current_lawyer_account).not_deleted.filter_by_team_member(current_lawyer.id))
    
    # 快速筛选选项
    @filter_options = {
      companies: Company.ordered.pluck(:name, :id),
      team_members: LawyerAccount.ordered.pluck(:name, :id),
      statuses: %w[preparing filed trial judged execution settled closed],
      stages: %w[arbitration first_trial second_trial execution retrial resume_execution],
      case_types: Case.not_deleted.distinct.pluck(:case_type).compact,
      priorities: Case::PRIORITIES.keys
    }
    
    # 加载保存的筛选条件
    if current_user
      @saved_filters = CaseFilter.where(user: current_user).ordered
    end
    
    render :index
  end
  
  def my_lead_cases
    unless current_lawyer
      redirect_to cases_path, alert: '只有律师可以查看主办案件'
      return
    end
    
    @filter_params = filter_params
    @cases = Case.accessible_by(current_lawyer_account)
                  .not_deleted
                  .filter_by_lead_lawyer(current_lawyer.id)
                  .includes(:company, :case_team_members)
                  .apply_filters(@filter_params)
                  .page(params[:page]).per(20)
    
    @stats = calculate_stats(Case.accessible_by(current_lawyer_account).not_deleted.filter_by_lead_lawyer(current_lawyer.id))
    
    # 快速筛选选项
    @filter_options = {
      companies: Company.ordered.pluck(:name, :id),
      team_members: LawyerAccount.ordered.pluck(:name, :id),
      statuses: %w[preparing filed trial judged execution settled closed],
      stages: %w[arbitration first_trial second_trial execution retrial resume_execution],
      case_types: Case.not_deleted.distinct.pluck(:case_type).compact,
      priorities: Case::PRIORITIES.keys
    }
    
    # 加载保存的筛选条件
    if current_user
      @saved_filters = CaseFilter.where(user: current_user).ordered
    end
    
    render :index
  end
  
  def team_workload
    unless current_lawyer
      redirect_to cases_path, alert: '只有律师可以查看团队工作量'
      return
    end
    
    @workload_stats = LawyerAccount.all.map do |lawyer|
      {
        lawyer: lawyer,
        total_cases: Case.filter_by_team_member(lawyer.id).count,
        lead_cases: Case.filter_by_lead_lawyer(lawyer.id).count,
        active_cases: Case.filter_by_team_member(lawyer.id).where(status: ['filed', 'trial', 'judged', 'execution']).count
      }
    end
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
    
    # 如果是从合同快速创建，预填充数据
    if params[:from_contract_id].present?
      @source_contract = Contract.find(params[:from_contract_id])
      prefill_case_from_contract(@case, @source_contract)
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
      # 如果是从合同创建的案件，建立关联
      if params[:from_contract_id].present?
        source_contract = Contract.find_by(id: params[:from_contract_id])
        if source_contract
          source_contract.update(related_case_id: @case.id)
        end
      end
      
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
    if lawyer?
      @companies = Company.ordered
      @selected_company = @case.company
    end
  end

  def update
    # 分离出所有附件参数，单独处理
    attachment_fields = [:attachments, :filing_attachments, :hearing_attachments, :judgement_attachments, :archived_attachments]
    attachments_data = {}
    
    attachment_fields.each do |field|
      if params[:case] && params[:case][field]
        attachments_data[field] = params[:case][field]
      end
    end
    
    # 使用不包含附件的参数更新案件
    update_params = case_params.except(*attachment_fields)
    
    if @case.update(update_params)
      # 如果有新附件，追加而不是替换
      attachment_fields.each do |field|
        if attachments_data[field].present?
          attachments_data[field].each do |attachment|
            @case.send(field).attach(attachment) if attachment.present?
          end
        end
      end
      
      redirect_to case_path(@case), notice: '案件信息已更新'
    else
      if lawyer?
        @companies = Company.ordered
        @selected_company = @case.company
      end
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # 验证当前用户的密码
    if lawyer?
      unless current_lawyer.authenticate(params[:confirm_password])
        flash[:alert] = '密码验证失败，无法删除案件'
        redirect_to case_path(@case)
        return
      end
    elsif company_user?
      unless current_company_user.authenticate(params[:confirm_password])
        flash[:alert] = '密码验证失败，无法删除案件'
        redirect_to case_path(@case)
        return
      end
    end
    
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
  
  def export_all_materials
    # 只有律师和律师助理可以导出案件档案
    unless current_lawyer
      redirect_to case_path(@case), alert: '您没有权限导出案件档案'
      return
    end
    
    # 生成完整案件档案压缩包
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
      add_attachments_to_zip(zip, @case.property_preservation_attachments, "财产保全附件")
      
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
      
      # 添加律师意见（所有已审核通过的意见）
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
    filename = "#{@case.name}_完整档案_#{Time.current.strftime('%Y%m%d')}.zip"
    send_data zip_stream.read, filename: filename, type: 'application/zip'
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
      add_attachments_to_zip(zip, @case.property_preservation_attachments, "财产保全附件")
      
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
  
  def append_attachments
    # 只有律师可以追加附件
    unless current_lawyer
      redirect_to case_path(@case), alert: '只有律师可以追加案件材料'
      return
    end
    
    if params[:case] && params[:case][:attachments].present?
      # 逐个附加文件，而不是替换
      success_count = 0
      error_messages = []
      
      params[:case][:attachments].each do |attachment|
        next if attachment.blank?
        
        begin
          @case.attachments.attach(attachment)
          
          # 检查验证错误
          if @case.errors[:attachments].any?
            error_messages << @case.errors[:attachments].last
            @case.errors.delete(:attachments)
            # 移除刚才附加的无效附件
            @case.attachments.last.purge if @case.attachments.attached?
          else
            success_count += 1
          end
        rescue => e
          error_messages << "文件 #{attachment.original_filename} 上传失败：#{e.message}"
        end
      end
      
      # 根据结果返回不同消息
      if success_count > 0 && error_messages.empty?
        redirect_to case_path(@case), notice: "案件材料已添加（共 #{success_count} 个文件）"
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
  
  def update_property_preservation
    # 只有律师可以更新财产保全信息
    unless current_lawyer
      redirect_to case_path(@case), alert: '您没有权限更新财产保全信息'
      return
    end
    
    # 如果需要保存到历史，先保存当前记录
    if params[:save_to_history] == '1' && @case.property_preservation_deadline.present?
      @case.add_property_preservation_record
    end
    
    # 更新财产保全字段
    if @case.update(property_preservation_params.except(:property_preservation_attachments))
      # 处理附件（追加而不是替换）
      if params[:case] && params[:case][:property_preservation_attachments].present?
        params[:case][:property_preservation_attachments].each do |attachment|
          @case.property_preservation_attachments.attach(attachment) if attachment.present?
        end
      end
      
      redirect_to case_path(@case), notice: '财产保全信息已更新'
    else
      redirect_to case_path(@case), alert: '更新失败，请检查输入信息'
    end
  end
  
  # 更新律师费信息
  def update_lawyer_fee
    unless current_lawyer
      redirect_to case_path(@case), alert: '您没有权限更新律师费信息'
      return
    end
    
    lawyer_fee_params = params.require(:case).permit(
      :lawyer_fee,
      :lawyer_fee_payment_terms,
      :agency_contract,
      :lawyer_fee_invoice
    )
    
    if @case.update(lawyer_fee_params)
      redirect_to case_path(@case, anchor: 'collaboration'), notice: '律师费信息已保存'
    else
      redirect_to case_path(@case, anchor: 'collaboration'), alert: "保存失败：#{@case.errors.full_messages.join(', ')}"
    end
  end
  
  # 添加案件关联
  def add_relation
    unless current_lawyer
      redirect_to case_path(@case), alert: '只有律师可以管理案件关联'
      return
    end
    
    to_case_id = params[:to_case_id]
    relation_type = params[:relation_type]
    
    if to_case_id.blank? || relation_type.blank?
      redirect_to case_path(@case), alert: '请选择关联案件和关系类型'
      return
    end
    
    to_case = Case.find_by(id: to_case_id)
    unless to_case
      redirect_to case_path(@case), alert: '目标案件不存在'
      return
    end
    
    if to_case.id == @case.id
      redirect_to case_path(@case), alert: '不能关联自己'
      return
    end
    
    # 检查是否已存在关联
    if @case.case_relations_as_from.exists?(to_case_id: to_case.id)
      redirect_to case_path(@case), alert: '该关联已存在'
      return
    end
    
    relation = @case.case_relations_as_from.new(
      to_case_id: to_case.id,
      relation_type: relation_type
    )
    
    if relation.save
      redirect_to case_path(@case), notice: "已成功关联案件：#{to_case.name}"
    else
      redirect_to case_path(@case), alert: "关联失败：#{relation.errors.full_messages.join(', ')}"
    end
  end
  
  # 删除案件关联
  def remove_relation
    unless current_lawyer
      redirect_to case_path(@case), alert: '只有律师可以管理案件关联'
      return
    end
    
    relation_id = params[:relation_id]
    
    relation = @case.case_relations_as_from.find_by(id: relation_id)
    unless relation
      redirect_to case_path(@case), alert: '关联不存在'
      return
    end
    
    to_case_name = relation.to_case.name
    
    if relation.destroy
      redirect_to case_path(@case), notice: "已取消与 #{to_case_name} 的关联"
    else
      redirect_to case_path(@case), alert: '删除关联失败'
    end
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
                 # 如果 URL 参数中有 company_id，设置到 session 中
                 if params[:company_id].present?
                   if params[:company_id] == 'all'
                     # 'all' 表示查看全部企业，清空 session
                     session[:viewing_company_id] = nil
                     @viewing_company = nil
                   else
                     company = Company.find_by(id: params[:company_id])
                     if company
                       session[:viewing_company_id] = company.id
                       @viewing_company = nil  # 清除缓存，确保 viewing_company 读取最新的 session 值
                     end
                   end
                 end
                 
                 # 律师可以选择企业或查看全部企业
                 if session[:viewing_company_id]
                   Company.find(session[:viewing_company_id])
                 else
                   # 全部企业模式：返回 nil，允许查看所有案件
                   nil
                 end
               end
    
    # 只有企业用户在未找到公司时才重定向
    if current_company_user && @company.nil?
      redirect_to root_path, alert: '未找到公司'
    end
  end

  def set_case
    if current_lawyer
      # 律师可以访问所有公司的案件
      @case = Case.find(params[:id])
      # 更新 @company 为该案件所属的公司
      @company = @case.company
    elsif current_company_user
      # 🔒 企业用户只能访问自己公司的案件
      # 使用 find 方法，如果找不到会抛出 ActiveRecord::RecordNotFound
      @case = current_company_user.company.cases.find(params[:id])
      @company = current_company_user.company
    else
      raise ActiveRecord::RecordNotFound, "Case not found or access denied"
    end
  end

  def case_params
    params.require(:case).permit(
      :company_id, :name, :case_number, :case_type, :court_name, :status, :stage,
      :filing_at, :hearing_at, :judgement_received_at, :archived_at,
      :closing_at, :appeal_deadline_date, :summary, :priority, :estimated_end_date,
      :our_party_role, :counterparty_role,
      # 审判员和书记员信息
      :judge_name, :judge_phone, :clerk_name, :clerk_phone,
      # 标的额相关
      :claim_amount, :awarded_amount, :litigation_fee, :lawyer_fee, :amount_status,
      # 律师费回款与开票信息
      :lawyer_fee_payment_status, :lawyer_fee_received, :lawyer_fee_received_at, :lawyer_fee_payment_terms,
      :lawyer_fee_invoice_issued, :lawyer_fee_invoice_number, :lawyer_fee_invoice_amount, :lawyer_fee_invoice_issued_at,
      # 当事人信息
      :our_party_name, :counterparty_name, :counterparty_lawyer, :counterparty_lawfirm, :counterparty_contact,
      # 案件结局
      :case_outcome,
      # 执行阶段
      :execution_start_at, :execution_deadline, :executed_amount, :execution_status, :execution_notes,
      # 数组字段
      tags: [],
      attachments: [],
      filing_attachments: [],
      hearing_attachments: [],
      judgement_attachments: [],
      archived_attachments: [],
      # JSON字段 - 在控制器中需要处理成JSON
      third_parties: [],
      claims: [:content, :amount, :status],
      judgement_result: [],
      execution_measures: [],
      # 嵌套属性
      case_team_members_attributes: [:id, :lawyer_account_id, :role, :joined_at, :_destroy],
      case_clients_attributes: [:id, :company_id, :role, :position, :joined_at, :notes, :_destroy]
    )
  end
  
  def filter_params
    params.permit(
      :keyword, :company_id, :team_member_id, :lead_lawyer_id,
      :sort_by, :sort_direction, :hearing_days, :appeal_days,
      :filed_from, :filed_to, :has_property_preservation,
      statuses: [], stages: [], case_types: [], priorities: []
    )
  end
  
  def calculate_stats(scope)
    {
      total: scope.count,
      pending: scope.where(status: 'pending').count,
      investigating: scope.where(status: 'investigating').count,
      in_court: scope.where(status: 'in_court').count,
      closed: scope.where(status: 'closed').count,
      urgent_hearings: scope.where('hearing_at BETWEEN ? AND ?', Time.current, 7.days.from_now).count,
      appeal_deadlines: scope.where('appeal_deadline_date BETWEEN ? AND ?', Date.today, 10.days.from_now).count
    }
  end
  
  def property_preservation_params
    params.require(:case).permit(
      :property_preservation_applied_at,
      :property_preservation_deadline,
      property_preservation_attachments: []
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
  
  # 收集案件的所有日期事件
  def collect_calendar_events(cases, event_types)
    events = []
    
    cases.each do |kase|
      # 立案日期
      if event_types.include?('立案日期') && kase.filing_at.present?
        events << {
          date: kase.filing_at,
          type: '立案日期',
          case: kase,
          label: "立案：#{kase.name}",
          color: 'info',
          icon: 'file-text'
        }
      end
      
      # 开庭时间
      if event_types.include?('开庭时间') && kase.hearing_at.present?
        color = if kase.hearing_at < Time.current
          'success'  # 已开庭
        elsif kase.hearing_at < 7.days.from_now
          'danger'   # 7天内开庭
        elsif kase.hearing_at < 15.days.from_now
          'warning'  # 15天内开庭
        else
          'info'
        end
        
        events << {
          date: kase.hearing_at,
          type: '开庭时间',
          case: kase,
          label: "开庭：#{kase.name}",
          color: color,
          icon: 'gavel'
        }
      end
      
      # 判决领取
      if event_types.include?('判决领取') && kase.judgement_received_at.present?
        events << {
          date: kase.judgement_received_at,
          type: '判决领取',
          case: kase,
          label: "判决：#{kase.name}",
          color: 'success',
          icon: 'file-check'
        }
      end
      
      # 归档日期
      if event_types.include?('归档日期') && kase.archived_at.present?
        events << {
          date: kase.archived_at,
          type: '归档日期',
          case: kase,
          label: "归档：#{kase.name}",
          color: 'neutral',
          icon: 'archive'
        }
      end
      
      # 财产保全到期
      if event_types.include?('保全到期') && kase.property_preservation_deadline.present?
        color = if kase.property_preservation_deadline < Date.today
          'danger'  # 已过期
        elsif kase.property_preservation_deadline < 7.days.from_now.to_date
          'warning' # 即将到期
        else
          'info'
        end
        
        events << {
          date: kase.property_preservation_deadline,
          type: '保全到期',
          case: kase,
          label: "保全到期：#{kase.name}",
          color: color,
          icon: 'shield-alert'
        }
      end
      
      # 执行期限（预计结束日期）
      if event_types.include?('执行到期') && kase.estimated_end_date.present?
        color = if kase.estimated_end_date < Date.today
          'danger'
        elsif kase.estimated_end_date < 30.days.from_now.to_date
          'warning'
        else
          'info'
        end
        
        events << {
          date: kase.estimated_end_date,
          type: '执行到期',
          case: kase,
          label: "执行期限：#{kase.name}",
          color: color,
          icon: 'clock'
        }
      end
    end
    
    events.sort_by { |e| e[:date] }
  end
  
  # 从合同预填充案件数据
  def prefill_case_from_contract(case_obj, contract)
    # 基本信息
    case_obj.name = "《#{contract.name}》纠纷案件"
    
    # 对方角色（诉讼地位）
    case_obj.counterparty_role = contract.counterparty_role if contract.counterparty_role.present?
    
    # 我方角色（根据对方角色推断）
    if contract.counterparty_role.present?
      case_obj.our_party_role = contract.counterparty_role == '甲方' ? '被告' : '原告'
    else
      case_obj.our_party_role = '原告'
    end
    
    # 案件摘要（包含合同背景信息）
    summary_parts = []
    summary_parts << "原合同名称：#{contract.name}"
    summary_parts << "签订日期：#{contract.signed_at.strftime('%Y年%m月%d日')}" if contract.signed_at
    summary_parts << "合同金额：#{contract.contract_amount}#{contract.currency || '元'}" if contract.contract_amount.present?
    summary_parts << "对方：#{contract.counterparty_name}" if contract.counterparty_name.present?
    
    if contract.counterparty_unified_code.present?
      summary_parts << "对方统一社会信用代码：#{contract.counterparty_unified_code}"
    end
    
    if contract.counterparty_legal_rep.present?
      summary_parts << "对方法定代表人：#{contract.counterparty_legal_rep}"
    end
    
    if contract.counterparty_address.present?
      summary_parts << "对方地址：#{contract.counterparty_address}"
    end
    
    if contract.counterparty_contact.present? || contract.counterparty_phone.present?
      contact_info = [contract.counterparty_contact, contract.counterparty_phone].compact.join(' ')
      summary_parts << "对方联系方式：#{contact_info}"
    end
    
    summary_parts << "争议状态：#{contract.dispute_status}" if contract.dispute_status.present?
    
    if contract.dispute_occurred_at.present?
      summary_parts << "争议发生日期：#{contract.dispute_occurred_at.strftime('%Y年%m月%d日')}"
    end
    
    if contract.litigation_amount.present?
      summary_parts << "诉讼标的金额：#{contract.litigation_amount}元"
    end
    
    if contract.litigation_notes.present?
      summary_parts << "\n诉讼备注：\n#{contract.litigation_notes}"
    end
    
    case_obj.summary = summary_parts.join("\n")
    
    # 设置初始状态
    case_obj.status = 'investigating'
    case_obj.stage = 'first_trial'
    case_obj.priority = contract.has_high_risk? ? 'high' : 'normal'
    
    # 如果合同有争议发生日期，可以作为参考
    if contract.dispute_occurred_at.present?
      case_obj.filing_at = contract.dispute_occurred_at
    end
  end
  
  # 计算案件的律师待办事项
  def calculate_pending_tasks_for_case(case_record)
    tasks = []
    
    # 即将开庭（7天内）
    if case_record.hearing_at.present? && case_record.hearing_at > Time.current && case_record.hearing_at < 7.days.from_now
      days_until = ((case_record.hearing_at - Time.current) / 1.day).ceil
      tasks << {
        type: :hearing_upcoming,
        text: "#{days_until}天后开庭（#{case_record.hearing_at.strftime('%m月%d日 %H:%M')}）",
        anchor: '#progress'
      }
    end
    
    # 上诉/再审期限临近（15天内）
    if case_record.show_appeal_deadline_reminder?
      days_left = case_record.days_until_effective_appeal_deadline
      if days_left <= 15
        tasks << {
          type: :appeal_deadline,
          text: "#{case_record.appeal_deadline_type}仅剩#{days_left}天",
          anchor: '#progress'
        }
      end
    end
    
    # 财产保全到期提醒（7天内）
    if case_record.property_preservation_deadline.present?
      days_left = case_record.property_preservation_days_left
      if days_left >= 0 && days_left <= 7
        tasks << {
          type: :property_preservation_expiring,
          text: "财产保全将于#{days_left}天后到期",
          anchor: '#preservation'
        }
      end
    end
    
    # 未审查的工作记录（最近3天新增）
    recent_logs_count = case_record.work_logs.where('created_at > ?', 3.days.ago).count
    if recent_logs_count > 0
      tasks << {
        type: :unreviewed_work_logs,
        text: "有#{recent_logs_count}条新工作记录待查看",
        anchor: '#work-logs'
      }
    end
    
    tasks
  end
end
