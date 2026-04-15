# 通用附件删除控制器
# 处理所有 ActiveStorage 附件的删除操作
class AttachmentsController < ApplicationController
  before_action :find_attachment

  # DELETE /attachments/:id
  def destroy
    record = @attachment.record
    
    # 权限检查：确保用户有权限删除该附件
    unless can_delete_attachment?(record)
      render turbo_stream: turbo_stream.replace(
        "attachment_#{@attachment.id}",
        partial: 'shared/alert',
        locals: { type: 'danger', message: '您没有权限删除此附件' }
      ), status: :forbidden
      return
    end

    # 删除附件
    @attachment.purge
    
    # 直接渲染 Turbo Stream 模板（destroy.turbo_stream.erb）
  end

  private

  def find_attachment
    @attachment = ActiveStorage::Attachment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render turbo_stream: turbo_stream.replace(
      "attachment_#{params[:id]}",
      partial: 'shared/alert',
      locals: { type: 'danger', message: '附件不存在' }
    ), status: :not_found
  end

  def can_delete_attachment?(record)
    # 根据不同的记录类型判断权限
    case record
    when Contract, Case, MajorIssue
      # 业务对象附件：需要有编辑权限
      if lawyer?
        record.editable_by?(current_lawyer_account)
      elsif company_user?
        # 企业用户需要是同公司且有管理权限
        record.company_id == viewing_company&.id &&
          current_company_user.can_manage_attachments?
      else
        false
      end
      
    when Reconciliation
      # 对账单附件：通过合同判断权限
      if lawyer?
        record.contract.editable_by?(current_lawyer_account)
      elsif company_user?
        record.contract.company_id == viewing_company&.id &&
          current_company_user.can_manage_attachments?
      else
        false
      end
      
    when Comment
      # 评论附件：只有作者和有删除评论权限的人能删
      if lawyer?
        record.author == current_lawyer_account ||
          record.commentable.deletable_by?(current_lawyer_account)
      elsif company_user?
        record.author == current_company_user
      else
        false
      end
      
    when WorkLog
      # 工作日志附件：只有作者能删
      record.author == current_user
      
    else
      false
    end
  end
end
