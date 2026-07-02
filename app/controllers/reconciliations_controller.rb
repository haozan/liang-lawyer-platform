class ReconciliationsController < ApplicationController
  before_action :require_authentication
  before_action :set_contract
  before_action :set_reconciliation, only: [:destroy, :mark_as_reviewed]

  def create
    @reconciliation = @contract.reconciliations.build(reconciliation_params)
    @reconciliation.uploaded_by = current_user_name
    @reconciliation.uploaded_at = Time.current

    # 合并年月为 period 格式
    if params[:reconciliation][:period_year].present? && params[:reconciliation][:period_month].present?
      year = params[:reconciliation][:period_year]
      month = params[:reconciliation][:period_month].to_s.rjust(2, '0')
      @reconciliation.period = "#{year}-#{month}"
    end

    if @reconciliation.save
      redirect_to contract_path(@contract), notice: "对账单上传成功"
    else
      redirect_to contract_path(@contract), alert: "上传失败：#{@reconciliation.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @reconciliation.destroy
    redirect_to contract_path(@contract), notice: "对账单已删除"
  end

  def mark_as_reviewed
    unless lawyer?
      redirect_to contract_path(@contract), alert: "无权操作" and return
    end

    @reconciliation.mark_as_reviewed!(current_lawyer)
    redirect_to contract_path(@contract), notice: "对账单已标记为已审查"
  end

  private

  def require_authentication
    redirect_to login_path, alert: '请先登录' unless current_user || current_lawyer
  end

  def set_contract
    @contract = Contract.find(params[:contract_id])
  end

  def set_reconciliation
    @reconciliation = @contract.reconciliations.find(params[:id])
  end

  def reconciliation_params
    params.require(:reconciliation).permit(
      :period, :notes, :receivable_amount, :received_amount,
      attachments: []
    )
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
end
