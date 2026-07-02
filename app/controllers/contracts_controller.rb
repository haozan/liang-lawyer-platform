class ContractsController < ApplicationController
  include CompanyResolvable
  
  before_action :set_company
  before_action :require_contract_access
  before_action :set_contract, only: [:show, :edit, :update, :destroy, :mark_as_reviewed, :export_archive, :renew, :renewal_settings, :append_evidence_files, :new_case_from_contract]
  
  # 合同关键日期日历视图
  def calendar
    # 获取当前月份（可通过参数切换）
    @year = params[:year]&.to_i || Date.today.year
    @month = params[:month]&.to_i || Date.today.month
    @current_date = Date.new(@year, @month, 1)
    
    # 获取筛选条件
    @event_types = params[:event_types] || ['签订日期', '到期日期', '履行开始', '履行结束', '交付日期', '验收日期', '质保到期', '最后联系', '下次跟进', '争议发生', '案件结案', '最后续签']
    @status_filter = params[:status]
    
    # 构建查询（律师选了企业时与企业员工视角一致）
    if lawyer? && @company
      @contracts = @company.contracts
    elsif lawyer?
      @contracts = Contract.accessible_by(current_lawyer_account)
    elsif @company
      @contracts = @company.contracts
    else
      @contracts = Contract.all
    end
    
    # 状态筛选
    @contracts = @contracts.where(status: @status_filter) if @status_filter.present?
    
    # 收集所有日期事件
    @calendar_events = collect_calendar_events(@contracts, @event_types)
    
    # 按日期分组
    @events_by_date = @calendar_events.group_by { |event| event[:date].to_date }
  end

  def index
    # 使用团队权限过滤合同
    # 律师选了企业时，与企业员工视角完全一致（只看该企业数据）
    if lawyer? && @company
      # 律师已选定某企业：与企业员工视角一致
      @contracts = @company.contracts.includes(:related_case).ordered
      @contracts = @contracts.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?
      if params[:tag_ids].present?
        tag_ids = params[:tag_ids].is_a?(Array) ? params[:tag_ids] : [params[:tag_ids]]
        @contracts = @contracts.tagged_with(tag_ids)
      end
      @available_tags = @company.contract_tags.ordered
    elsif lawyer?
      # 律师未选企业：看全部有权限合同
      @contracts = Contract.accessible_by(current_lawyer_account).includes(:company, :related_case).ordered
      @contracts = @contracts.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?
      if params[:tag_ids].present?
        tag_ids = params[:tag_ids].is_a?(Array) ? params[:tag_ids] : [params[:tag_ids]]
        @contracts = @contracts.tagged_with(tag_ids)
      end
      @available_tags = ContractTag.ordered
    elsif @company
      # 单个企业：显示该企业的合同
      @contracts = @company.contracts.includes(:related_case).ordered
      @contracts = @contracts.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?
      if params[:tag_ids].present?
        tag_ids = params[:tag_ids].is_a?(Array) ? params[:tag_ids] : [params[:tag_ids]]
        @contracts = @contracts.tagged_with(tag_ids)
      end
      @available_tags = @company.contract_tags.ordered
    else
      # 全部企业：显示所有合同
      @contracts = Contract.includes(:company, :related_case).ordered
      @contracts = @contracts.where("name LIKE ?", "%#{params[:q]}%") if params[:q].present?
      if params[:tag_ids].present?
        tag_ids = params[:tag_ids].is_a?(Array) ? params[:tag_ids] : [params[:tag_ids]]
        @contracts = @contracts.tagged_with(tag_ids)
      end
      @available_tags = ContractTag.ordered
    end
  end

  def new
    if lawyer? && @company
      # 律师已选定企业：直接在该企业下创建，无需再选
      @selected_company = params[:company_id].present? ? Company.find(params[:company_id]) : @company
      @contract = Contract.new
    elsif lawyer?
      # 律师未选企业：需要选择企业
      @companies = Company.accessible_by_lawyer(current_lawyer).ordered
      @selected_company = params[:company_id].present? ? Company.find(params[:company_id]) : nil
      @contract = Contract.new
    else
      # 企业用户只能为自己的企业创建合同
      @contract = @company.contracts.new
    end
    
    # 获取创建模式（quick 或 full）
    @mode = params[:mode] || 'quick'  # 默认使用快速模式
  end

  def create
    if lawyer? && @company
      # 律师已选定企业：直接在该企业下创建
      @contract = @company.contracts.new(contract_params.except(:company_id, :mode))
    elsif lawyer?
      # 律师未选企业：必须指定 company_id
      company_id = contract_params[:company_id]
      if company_id.blank?
        redirect_to new_contract_path, alert: '请选择合同所属企业' and return
      end
      target_company = Company.find(company_id)
      @contract = target_company.contracts.new(contract_params.except(:company_id, :mode))
    else
      # 企业用户只能为自己的企业创建合同
      @contract = @company.contracts.new(contract_params.except(:mode))
    end
    
    # 获取创建模式
    @mode = params[:contract][:mode] || 'quick'
    
    if @contract.save
      redirect_to contract_path(@contract), notice: "✅ 合同档案创建成功"
    else
      if lawyer? && @company
        @selected_company = @company
      elsif lawyer?
        @companies = Company.accessible_by_lawyer(current_lawyer).ordered
        @selected_company = @contract.company
      end
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # 加载合同评论和所有对账单评论
    contract_comment_ids = @contract.comments.pluck(:id)
    reconciliation_comment_ids = Comment.where(
      commentable_type: 'Reconciliation',
      commentable_id: @contract.reconciliations.pluck(:id)
    ).pluck(:id)
    @comments = Comment.where(id: contract_comment_ids + reconciliation_comment_ids).ordered
    @comment = @contract.comments.new
    
    # Prepare mentionable users for @ feature
    @mentionable_users = prepare_mentionable_users
    
    # 设置用户模式（律师模式 vs 企业模式）
    
    # 计算关键指标（用于两种模式）
    @key_metrics = calculate_key_metrics(@contract)
    
    # 计算律师待办事项（仅律师模式）
    @pending_tasks = lawyer? ? calculate_pending_tasks(@contract) : []
  end

  def edit
    if lawyer?
      @companies = Company.accessible_by_lawyer(current_lawyer).ordered
      @selected_company = @contract.company
    end
    @mode = params[:mode] || 'full'  # 编辑默认使用完整模式
  end

  def update
    if @contract.update(contract_params)
      redirect_to contract_path(@contract), notice: "合同档案已更新"
    else
      if lawyer?
        @companies = Company.accessible_by_lawyer(current_lawyer).ordered
        @selected_company = @contract.company
      end
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # 验证当前用户的密码
    if lawyer?
      unless current_lawyer.authenticate(params[:confirm_password])
        flash[:alert] = '密码验证失败，无法删除合同'
        redirect_to contract_path(@contract)
        return
      end
    elsif company_user?
      unless current_company_user.authenticate(params[:confirm_password])
        flash[:alert] = '密码验证失败，无法删除合同'
        redirect_to contract_path(@contract)
        return
      end
    end
    
    @contract.destroy
    redirect_to contracts_path, notice: "合同档案已删除"
  end
  
  # 标记合同为已审查（仅律师可以操作）
  def mark_as_reviewed
    unless lawyer?
      redirect_to contract_path(@contract), alert: "无权操作" and return
    end
    
    if @contract.update(
      reviewed_by_lawyer: true,
      reviewed_at: Time.current,
      reviewed_by_lawyer_id: current_lawyer.id
    )
      # 自动消除相关公告（系统自动）
      begin
        AnnouncementDismissal.dismiss!(
          announcement_type: 'contract_review',
          related: @contract,
          user: current_lawyer,
          reason: 'reviewed'
        )
      rescue
        # 忽略消除失败
      end
      
      redirect_to contract_path(@contract), notice: "✅ 合同已标记为已审查，相关公告已自动消除"
    else
      redirect_to contract_path(@contract), alert: "操作失败"
    end
  end
  
  # 批量标记多个合同为已审查（仅律师可以操作）
  def batch_mark_as_reviewed
    unless lawyer?
      redirect_to contracts_path, alert: '无权操作' and return
    end
    
    contract_ids = params[:contract_ids] || []
    if contract_ids.empty?
      redirect_to contracts_path, alert: '未选择任何合同' and return
    end
    
    # 查找需要标记的合同（律师选了企业时与企业视角一致）
    contracts = if lawyer? && @company
      @company.contracts.where(id: contract_ids)
    elsif lawyer?
      Contract.accessible_by(current_lawyer_account).where(id: contract_ids)
    elsif @company
      @company.contracts.where(id: contract_ids)
    else
      Contract.where(id: contract_ids)
    end
    
    @marked_count = 0
    contracts.each do |contract|
      if contract.update(
        reviewed_by_lawyer: true,
        reviewed_at: Time.current,
        reviewed_by_lawyer_id: current_lawyer.id
      )
        @marked_count += 1
        
        # 自动消除相关公告
        begin
          AnnouncementDismissal.dismiss!(
            announcement_type: 'contract_review',
            related: contract,
            user: current_lawyer,
            reason: 'reviewed'
          )
        rescue
          # 忽略消除失败
        end
      end
    end
    
    redirect_to contracts_path, notice: "✅ 已标记 #{@marked_count} 个合同为已审查"
  end
  
  # 导出合同完整档案（所有登录用户可导出）
  def export_archive
    # 生成完整合同档案压缩包
    require 'zip'
    require 'stringio'
    
    zip_stream = Zip::OutputStream.write_buffer do |zip|
      # 添加合同基本信息文本文件
      contract_info = generate_contract_info_text(@contract)
      zip.put_next_entry("合同信息.txt")
      zip.write contract_info
      
      # 添加合同文件
      if @contract.file.attached?
        zip.put_next_entry("合同文件/#{@contract.file.filename}")
        zip.write @contract.file.download
      end
      
      # 添加所有对账单
      @contract.reconciliations.ordered.each_with_index do |reconciliation, index|
        folder_prefix = "对账单/#{reconciliation.period_display}_对账单"
        
        # 添加对账信息文本
        reconciliation_info = generate_reconciliation_info_text(reconciliation)
        zip.put_next_entry("#{folder_prefix}/对账信息.txt")
        zip.write reconciliation_info
        
        # 添加对账单附件
        if reconciliation.attachments.attached?
          reconciliation.attachments.each do |attachment|
            zip.put_next_entry("#{folder_prefix}/#{attachment.filename}")
            zip.write attachment.download
          end
        end
        
        # 添加对账单的评论
        if reconciliation.comments.any?
          reconciliation.comments.ordered.each_with_index do |comment, comment_index|
            comment_text = "作者：#{comment.author_name}\n时间：#{comment.created_at.strftime('%Y年%m月%d日 %H:%M')}\n内容：\n#{comment.content}"
            zip.put_next_entry("#{folder_prefix}/评论/#{comment_index + 1}_#{comment.author_name}.txt")
            zip.write comment_text
            
            # 添加评论附件
            if comment.attachments.attached?
              comment.attachments.each do |attachment|
                zip.put_next_entry("#{folder_prefix}/评论/#{comment_index + 1}_#{comment.author_name}_附件/#{attachment.filename}")
                zip.write attachment.download
              end
            end
          end
        end
      end
      
      # 添加律师审查意见（针对合同本身的评论）
      contract_comments = @contract.comments.approved.ordered
      if contract_comments.any?
        contract_comments.each_with_index do |comment, index|
          comment_text = "作者：#{comment.author_name}\n时间：#{comment.created_at.strftime('%Y年%m月%d日 %H:%M')}\n内容：\n#{comment.content}"
          zip.put_next_entry("律师审查意见/#{index + 1}_#{comment.author_name}_#{comment.created_at.strftime('%Y%m%d')}.txt")
          zip.write comment_text
          
          # 添加审查意见附件
          if comment.attachments.attached?
            comment.attachments.each do |attachment|
              zip.put_next_entry("律师审查意见/#{index + 1}_#{comment.author_name}_附件/#{attachment.filename}")
              zip.write attachment.download
            end
          end
        end
      end
    end
    
    zip_stream.rewind
    filename = "#{@contract.name}_完整档案_#{Time.current.strftime('%Y%m%d')}.zip"
    send_data zip_stream.read, filename: filename, type: 'application/zip'
  end
  
  # 一键续签：基于现有合同创建新合同
  def renew
    # 检查续签意向
    unless @contract.renewal_intention == '续约'
      redirect_to contract_path(@contract), alert: "合同续签意向不是'续约'，无法执行一键续签" and return
    end
    
    # 计算新合同的日期
    contract_duration = (@contract.end_at - @contract.signed_at).to_i
    new_signed_at = @contract.end_at + 1.day
    new_end_at = new_signed_at + contract_duration.days
    
    # 复制合同信息创建新合同
    new_contract = @contract.company.contracts.new(
      # 基本信息
      name: "#{@contract.name}（续签）",
      signed_at: new_signed_at,
      end_at: new_end_at,
      status: 'active',
      
      # 合同双方
      our_party_role: @contract.our_party_role,
      our_signatory: @contract.our_signatory,
      counterparty_name: @contract.counterparty_name,
      counterparty_role: @contract.counterparty_role,
      counterparty_type: @contract.counterparty_type,
      counterparty_unified_code: @contract.counterparty_unified_code,
      counterparty_legal_rep: @contract.counterparty_legal_rep,
      counterparty_address: @contract.counterparty_address,
      counterparty_contact: @contract.counterparty_contact,
      counterparty_phone: @contract.counterparty_phone,
      
      # 合同基本信息
      contract_type: @contract.contract_type,
      contract_amount: @contract.contract_amount,
      currency: @contract.currency,
      payment_method: @contract.payment_method,
      payment_terms: @contract.payment_terms,
      
      # 违约责任
      penalty_clause: @contract.penalty_clause,
      liquidated_damages: @contract.liquidated_damages,
      
      # 争议解决
      dispute_resolution: @contract.dispute_resolution,
      arbitration_institution: @contract.arbitration_institution,
      jurisdiction_court: @contract.jurisdiction_court,
      applicable_law: @contract.applicable_law,
      
      # 续约管理
      auto_renewal: @contract.auto_renewal,
      renewal_notice_period: @contract.renewal_notice_period,
      renewal_intention: '待定',
      
      # 内部管理
      client_contact: @contract.client_contact,
      client_contact_phone: @contract.client_contact_phone,
      client_dept: @contract.client_dept,
      assigned_lawyer_id: @contract.assigned_lawyer_id,
      reconciliation_cycle_days: @contract.reconciliation_cycle_days,
      
      # 标记为续签合同
      internal_notes: "本合同由【#{@contract.name}】（ID:#{@contract.id}）续签生成"
    )
    
    # 不验证文件，允许稍后上传
    if new_contract.save(validate: false)
      # 更新原合同状态
      @contract.update(
        status: 'completed',
        renewal_notes: "已续签，新合同ID：#{new_contract.id}",
        internal_notes: (@contract.internal_notes.to_s + "\n\n已于#{Time.current.strftime('%Y年%m月%d日')}续签，新合同ID：#{new_contract.id}")
      )
      
      redirect_to edit_contract_path(new_contract), 
        notice: "✅ 续签合同已创建，请补充合同文件和其他信息"
    else
      redirect_to contract_path(@contract), 
        alert: "续签失败：#{new_contract.errors.full_messages.join(', ')}"
    end
  end
  
  # 续签配置页面
  def renewal_settings
    # 渲染续签配置表单
  end
  
  # 追加证据文件
  def append_evidence_files
    file_type = params[:file_type]
    files = params[:files]
    
    unless %w[delivery_proofs payment_proofs correspondence_files other_evidence_files].include?(file_type)
      render turbo_stream: turbo_stream.replace(
        "append_#{file_type}_form",
        partial: "contracts/append_file_form",
        locals: { contract: @contract, file_type: file_type, error: "无效的文件类型" }
      ), status: :unprocessable_entity and return
    end
    
    if files.blank?
      render turbo_stream: turbo_stream.replace(
        "append_#{file_type}_form",
        partial: "contracts/append_file_form",
        locals: { contract: @contract, file_type: file_type, error: "请选择要上传的文件" }
      ), status: :unprocessable_entity and return
    end
    
    # 追加文件到指定字段
    @contract.send(file_type).attach(files)
    
    # 返回更新后的文件列表
    render turbo_stream: [
      turbo_stream.replace(
        "#{file_type}_list",
        partial: "contracts/evidence_file_list",
        locals: { contract: @contract, file_type: file_type }
      ),
      turbo_stream.replace(
        "append_#{file_type}_form",
        partial: "contracts/append_file_form",
        locals: { contract: @contract, file_type: file_type, success: "文件已成功追加" }
      )
    ]
  end

  # 从合同快速创建案件
  def new_case_from_contract
    # 检查是否已关联案件
    if @contract.has_case?
      redirect_to case_path(@contract.related_case), notice: "该合同已关联案件" and return
    end
    
    # 重定向到新建案件页面，并传递合同ID参数
    redirect_to new_case_path(from_contract_id: @contract.id)
  end

  private

  # 收集合同的所有日期事件
  def collect_calendar_events(contracts, event_types)
    events = []
    
    contracts.each do |contract|
      # 签订日期
      if event_types.include?('签订日期') && contract.signed_at.present?
        events << {
          date: contract.signed_at,
          type: '签订日期',
          contract: contract,
          label: "签订：#{contract.name}",
          color: 'info',
          icon: 'file-signature'
        }
      end
      
      # 到期日期
      if event_types.include?('到期日期') && contract.end_at.present?
        color = if contract.expired?
          'danger'
        elsif contract.expiring_soon?
          'warning'
        else
          'success'
        end
        
        events << {
          date: contract.end_at,
          type: '到期日期',
          contract: contract,
          label: "到期：#{contract.name}",
          color: color,
          icon: 'calendar-x'
        }
      end
      
      # 履行开始日期
      if event_types.include?('履行开始') && contract.performance_start_date.present?
        events << {
          date: contract.performance_start_date,
          type: '履行开始',
          contract: contract,
          label: "履行开始：#{contract.name}",
          color: 'info',
          icon: 'play-circle'
        }
      end
      
      # 履行结束日期
      if event_types.include?('履行结束') && contract.performance_end_date.present?
        events << {
          date: contract.performance_end_date,
          type: '履行结束',
          contract: contract,
          label: "履行结束：#{contract.name}",
          color: 'success',
          icon: 'check-circle'
        }
      end
      
      # 交付日期
      if event_types.include?('交付日期') && contract.delivery_date.present?
        events << {
          date: contract.delivery_date,
          type: '交付日期',
          contract: contract,
          label: "交付：#{contract.name}",
          color: 'info',
          icon: 'truck'
        }
      end
      
      # 验收日期
      if event_types.include?('验收日期') && contract.acceptance_date.present?
        events << {
          date: contract.acceptance_date,
          type: '验收日期',
          contract: contract,
          label: "验收：#{contract.name}",
          color: 'success',
          icon: 'check-square'
        }
      end
      
      # 质保到期日期
      if event_types.include?('质保到期') && contract.warranty_end_date.present?
        events << {
          date: contract.warranty_end_date,
          type: '质保到期',
          contract: contract,
          label: "质保到期：#{contract.name}",
          color: 'warning',
          icon: 'shield-alert'
        }
      end
      
      # 最后联系日期
      if event_types.include?('最后联系') && contract.last_contact_date.present?
        events << {
          date: contract.last_contact_date,
          type: '最后联系',
          contract: contract,
          label: "最后联系：#{contract.name}",
          color: 'neutral',
          icon: 'phone'
        }
      end
      
      # 下次跟进日期
      if event_types.include?('下次跟进') && contract.next_follow_up_date.present?
        color = contract.next_follow_up_date < Date.today ? 'danger' : 'info'
        events << {
          date: contract.next_follow_up_date,
          type: '下次跟进',
          contract: contract,
          label: "跟进：#{contract.name}",
          color: color,
          icon: 'bell'
        }
      end
      
      # 争议发生日期
      if event_types.include?('争议发生') && contract.dispute_occurred_at.present?
        events << {
          date: contract.dispute_occurred_at,
          type: '争议发生',
          contract: contract,
          label: "争议：#{contract.name}",
          color: 'danger',
          icon: 'alert-triangle'
        }
      end
      
      # 案件结案日期
      if event_types.include?('案件结案') && contract.case_closed_at.present?
        events << {
          date: contract.case_closed_at,
          type: '案件结案',
          contract: contract,
          label: "结案：#{contract.name}",
          color: 'success',
          icon: 'file-check'
        }
      end
      
      # 最后续签日期
      if event_types.include?('最后续签') && contract.last_renewal_date.present?
        events << {
          date: contract.last_renewal_date,
          type: '最后续签',
          contract: contract,
          label: "续签：#{contract.name}",
          color: 'info',
          icon: 'refresh-cw'
        }
      end
    end
    
    # 按日期排序
    events.sort_by { |e| e[:date] }
  end

  # set_company 由 CompanyResolvable concern 提供

  def require_contract_access
    return if lawyer?
    return if current_company_user.present?
    redirect_to root_path, alert: "无权访问"
  end

  def set_contract
    if lawyer?
      # 律师可以访问所有公司的合同
      @contract = Contract.find(params[:id])
      # 更新 @company 为该合同所属的公司
      @company = @contract.company
    elsif company_user?
      # 🔒 企业用户只能访问自己公司的合同
      # 使用 find 方法，如果找不到会抛出 ActiveRecord::RecordNotFound
      @company = viewing_company
      @contract = @company.contracts.find(params[:id])
    else
      raise ActiveRecord::RecordNotFound, "Contract not found or access denied"
    end
  end

  def contract_params
    permitted_params = [
      :name, :signed_at, :end_at, :status, :reconciliation_cycle_days, :file, :mode,
      # 合同双方
      :our_party_role, :our_signatory,
      :counterparty_name, :counterparty_role, :counterparty_type, :counterparty_unified_code,
      :counterparty_legal_rep, :counterparty_address, :counterparty_contact, :counterparty_phone,
      # 合同基本信息
      :contract_number, :contract_title, :contract_type, :signing_location,
      # 金额与付款
      :contract_amount, :currency, :payment_method, :payment_terms,
      # 履行期限
      :performance_start_date, :performance_end_date, :delivery_date, :delivery_location,
      :acceptance_date, :warranty_period, :warranty_end_date,
      # 违约责任
      :penalty_clause, :liquidated_damages,
      # 争议解决
      :dispute_resolution, :arbitration_institution, :jurisdiction_court, :applicable_law,
      # 律师审查
      :legal_review_status, :legal_risk_level, :legal_risk_summary, :lawyer_suggestions,
      # 履行跟踪
      :performance_status, :performance_progress, :performance_notes,
      :last_contact_date, :next_follow_up_date,
      # 争议与诉讼
      :dispute_status, :dispute_occurred_at, :related_case_id, :litigation_amount, :litigation_notes,
      # 续约管理
      :auto_renewal, :renewal_notice_period, :renewal_intention, :renewal_notes,
      # 内部管理
      :client_contact, :client_contact_phone, :client_dept, :assigned_lawyer_id, :internal_notes,
      # 文件附件
      supplement_files: [], annex_files: [], delivery_proofs: [], payment_proofs: [],
      correspondence_files: [], other_evidence_files: [], assistant_lawyer_ids: []
    ]
    # 律师可以指定 company_id
    permitted_params << :company_id if lawyer?
    params.require(:contract).permit(permitted_params)
  end
  
  def prepare_mentionable_users
    users = []
    
    # Add lawyers and assistants
    LawyerAccount.all.each do |lawyer|
      users << {
        type: 'LawyerAccount',
        id: lawyer.id,
        name: lawyer.display_name
      }
    end
    
    # Add company users (if current user is company user)
    if company_user?
      @company.company_users.each do |user|
        users << {
          type: 'CompanyUser',
          id: user.id,
          name: user.display_name
        }
      end
    end
    
    users
  end
  
  # 计算关键指标
  def calculate_key_metrics(contract)
    # 计算剩余天数
    days_remaining = contract.end_at ? (contract.end_at - Date.today).to_i : nil
    
    {
      amount: contract.contract_amount || 0,
      days_remaining: days_remaining,
      progress: contract.performance_progress || 0,
      risk_level: contract.legal_risk_level || '未评估',
      status: contract.status,
      is_expiring: contract.expiring_soon?,
      is_expired: contract.expired?,
      has_high_risk: contract.has_high_risk?
    }
  end
  
  # 计算律师待办事项
  def calculate_pending_tasks(contract)
    tasks = []
    
    # 对账单待审查
    pending_reconciliations = contract.reconciliations.where(reviewed_by_lawyer: false).count
    if pending_reconciliations > 0
      tasks << {
        type: :reconciliation_review,
        count: pending_reconciliations,
        text: "#{pending_reconciliations}个对账单待审查",
        anchor: '#reconciliation'
      }
    end
    
    # 风险点需关注
    risk_count = 0
    risk_count += 1 if contract.has_high_risk?
    risk_count += 1 if contract.in_dispute?
    risk_count += 1 if contract.expired?
    if risk_count > 0
      tasks << {
        type: :risk_attention,
        count: risk_count,
        text: "#{risk_count}个风险点需关注",
        anchor: '#risk'
      }
    end
    
    # 续约决策即将到期
    if contract.needs_renewal_notice?
      tasks << {
        type: :renewal_decision,
        count: 1,
        text: "1个续约决策即将到期",
        anchor: '#risk'
      }
    end
    
    tasks
  end
  
  # 生成合同信息文本
  def generate_contract_info_text(contract)
    info = []
    info << "合同名称：#{contract.name}"
    info << "签订日期：#{contract.signed_at.strftime('%Y年%m月%d日')}" if contract.signed_at
    info << "到期日期：#{contract.end_at.strftime('%Y年%m月%d日')}" if contract.end_at
    info << "合同状态：#{contract.status_display}"
    info << "所属企业：#{contract.company.name}"
    info << "对账周期：每#{contract.reconciliation_cycle_days}天" if contract.reconciliation_cycle_days
    info << "律师审查状态：#{contract.reviewed_by_lawyer ? '已审查' : '待审查'}"
    if contract.reviewed_by_lawyer && contract.last_lawyer_comment_at
      info << "最后审查时间：#{contract.last_lawyer_comment_at.strftime('%Y年%m月%d日 %H:%M')}"
    end
    info << "创建时间：#{contract.created_at.strftime('%Y年%m月%d日 %H:%M')}"
    info.join("\n")
  end
  
  # 生成对账单信息文本
  def generate_reconciliation_info_text(reconciliation)
    info = []
    info << "对账期间：#{reconciliation.period_display}"
    info << "上传者：#{reconciliation.uploaded_by}"
    info << "上传时间：#{reconciliation.uploaded_at.strftime('%Y年%m月%d日 %H:%M')}"
    info << "律师审查状态：#{reconciliation.reviewed_by_lawyer ? '已审查' : '待审查'}"
    if reconciliation.notes.present?
      info << "\n备注："
      info << reconciliation.notes
    end
    if reconciliation.mentioned_users.present? && reconciliation.mentioned_users.is_a?(Array) && reconciliation.mentioned_users.any?
      info << "\n@提醒的人："
      reconciliation.mentioned_users.each do |user|
        info << "- #{user['name']}"
      end
    end
    info.join("\n")
  end
end
