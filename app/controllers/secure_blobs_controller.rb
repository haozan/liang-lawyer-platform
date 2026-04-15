# 安全文件访问控制器
# 所有通过ActiveStorage存储的文件必须经过此控制器进行权限验证
class SecureBlobsController < ApplicationController
  before_action :authenticate_user!
  
  def show
    # 1. 查找文件blob
    blob = ActiveStorage::Blob.find_signed!(params[:signed_id])
    attachment = ActiveStorage::Attachment.find_by!(blob_id: blob.id)
    record = attachment.record
    
    # 2. 权限检查
    unless can_access_attachment?(record)
      redirect_to root_path, alert: '您没有权限访问该文件'
      return
    end
    
    # 3. 设置响应头并直接发送文件
    disposition = params[:disposition] || 'inline'
    
    # 设置文件类型和下载方式
    response.headers['Content-Type'] = blob.content_type
    response.headers['Content-Disposition'] = "#{disposition}; filename=\"#{blob.filename}\"; filename*=UTF-8''#{ERB::Util.url_encode(blob.filename.to_s)}"
    
    # 设置缓存控制（预览文件可以缓存）
    if disposition == 'inline'
      response.headers['Cache-Control'] = 'private, max-age=3600'
    else
      response.headers['Cache-Control'] = 'private, no-cache'
    end
    
    # 设置安全相关的响应头
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'SAMEORIGIN'
    
    # 直接发送文件数据
    if blob.service.respond_to?(:path_for)
      # 本地存储：直接发送文件
      send_file blob.service.path_for(blob.key),
                type: blob.content_type,
                disposition: disposition,
                filename: blob.filename.to_s
    else
      # 云存储：下载并流式传输
      begin
        blob.download do |chunk|
          response.stream.write chunk
        end
      ensure
        response.stream.close
      end
    end
  end
  
  private
  
  # 判断当前用户是否可以访问附件
  def can_access_attachment?(record)
    case record
    when Contract, Case, MajorIssue
      # 业务对象附件：需要有该对象的访问权限
      if lawyer?
        record.accessible_by?(current_lawyer_account)
      elsif company_user?
        record.company_id == viewing_company&.id
      else
        false
      end
      
    when Reconciliation
      # 对账单附件：通过合同访问权限
      if lawyer?
        record.contract.accessible_by?(current_lawyer_account)
      elsif company_user?
        record.contract.company_id == viewing_company&.id
      else
        false
      end
      
    when Comment
      # 评论附件：能看到评论所在对象的人可以看附件
      commentable = record.commentable
      if lawyer?
        commentable.accessible_by?(current_lawyer_account)
      elsif company_user?
        commentable.company_id == viewing_company&.id
      else
        false
      end
      
    when WorkLog
      # 工作日志附件：能访问对应案件的人可以看附件
      case_record = record.case
      if lawyer?
        case_record.accessible_by?(current_lawyer_account)
      elsif company_user?
        case_record.company_id == viewing_company&.id
      else
        false
      end
      
    else
      # 未知类型的附件：默认拒绝访问
      false
    end
  end
  
  # 确保用户已登录
  def authenticate_user!
    unless lawyer? || company_user?
      redirect_to sign_in_path, alert: '请先登录'
    end
  end
end
