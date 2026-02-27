class ReconciliationsController < ApplicationController
  before_action :require_contract_access_or_lawyer
  before_action :set_contract
  before_action :set_reconciliation, only: [:destroy]

  def create
    @reconciliation = @contract.reconciliations.build(reconciliation_params)
    @reconciliation.uploaded_by = current_user_name
    @reconciliation.uploaded_at = Time.current
    
    if @reconciliation.save
      redirect_to contract_path(@contract), notice: "对账单上传成功"
    else
      redirect_to contract_path(@contract), alert: "上传失败：#{@reconciliation.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    if @reconciliation.destroy
      redirect_to contract_path(@contract), notice: "对账单已删除"
    else
      redirect_to contract_path(@contract), alert: "删除失败"
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
    params.require(:reconciliation).permit(:period, :notes, attachments: [])
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
    return if company_user? && current_company_user.role == 'contract'
    return if company_user? && current_company_user.role == 'boss'
    
    redirect_to root_path, alert: "没有权限访问该页面"
  end
end
