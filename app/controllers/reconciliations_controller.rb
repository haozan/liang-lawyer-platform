class ReconciliationsController < ApplicationController
  before_action :require_contract_access_or_lawyer
  before_action :set_contract
  before_action :set_reconciliation, only: [:destroy, :mark_as_reviewed]

  def create
    @reconciliation = @contract.reconciliations.build(reconciliation_params)
    @reconciliation.uploaded_by = current_user_name
    @reconciliation.uploaded_at = Time.current
    
    # Combine period_year and period_month into period format
    if params[:reconciliation][:period_year].present? && params[:reconciliation][:period_month].present?
      year = params[:reconciliation][:period_year]
      month = params[:reconciliation][:period_month].to_s.rjust(2, '0')
      @reconciliation.period = "#{year}-#{month}"
    end
    
    # Parse mentioned_users JSON if present
    if params[:reconciliation][:mentioned_users].present?
      begin
        mentioned_data = JSON.parse(params[:reconciliation][:mentioned_users])
        @reconciliation.mentioned_users = mentioned_data if mentioned_data.is_a?(Array)
      rescue JSON::ParserError
        # Silently ignore invalid JSON
      end
    end
    
    if @reconciliation.save
      # TODO: Send notification to mentioned users via ActionCable or email
      # For now, just flash a notice
      redirect_to contract_path(@contract), notice: "对账单上传成功"
    else
      redirect_to contract_path(@contract), alert: "上传失败：#{@reconciliation.errors.full_messages.join(', ')}"
    end
  end
  
  # 一键生成本月对账单（仅创建记录框架，用户需上传附件）
  def quick_create_current_month
    current_period = Time.current.strftime('%Y-%m')
    
    # 检查本月是否已上传对账单
    if Reconciliation.current_month_uploaded?(@contract)
      redirect_to contract_path(@contract), alert: "本月对账单已存在，无需重复创建" and return
    end
    
    # 创建本月对账单记录（无附件）
    @reconciliation = @contract.reconciliations.build(
      period: current_period,
      uploaded_by: current_user_name,
      uploaded_at: Time.current,
      notes: "快速创建的对账单记录，请补充上传附件"
    )
    
    # 不验证附件，允许创建空记录
    if @reconciliation.save(validate: false)
      redirect_to contract_path(@contract, anchor: "reconciliation-#{@reconciliation.id}"), 
        notice: "✅ 已创建#{current_period}对账单记录，请上传附件"
    else
      redirect_to contract_path(@contract), alert: "创建失败：#{@reconciliation.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    if @reconciliation.destroy
      redirect_to contract_path(@contract), notice: "对账单已删除"
    else
      redirect_to contract_path(@contract), alert: "删除失败"
    end
  end
  
  def mark_as_reviewed
    unless lawyer?
      redirect_to contract_path(@contract), alert: "无权操作" and return
    end
    
    if @reconciliation.mark_as_reviewed!(current_lawyer)
      begin
        AnnouncementDismissal.dismiss!(
          announcement_type: 'reconciliation_review_pending',
          related: @reconciliation,
          user: current_lawyer,
          reason: 'reviewed'
        )
      rescue
      end
      
      redirect_to contract_path(@contract), notice: "✅ 对账单已标记为已审查，相关公告已自动消除"
    else
      redirect_to contract_path(@contract), alert: "操作失败"
    end
  end

  private
  
  def set_contract
    @contract = Contract.find(params[:contract_id])
  end
  
  def set_reconciliation
    @reconciliation = @contract.reconciliations.find(params[:id])
  end
  
  def reconciliation_params
    params.require(:reconciliation).permit(:period, :notes, mentioned_users: [:type, :id, :name], attachments: [])
  end
  
  def current_user_name
    if lawyer?
      current_lawyer.name
    elsif company_user?
      current_company_user.name
    else
      'Unknown'
    end
  end
  
  def require_contract_access_or_lawyer
    return if lawyer?
    return if company_user?
    
    redirect_to root_path, alert: "没有权限访问该页面"
  end
end
