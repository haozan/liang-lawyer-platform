class CommentsController < ApplicationController
  before_action :require_authentication
  before_action :set_comment, only: [:destroy, :append_attachments, :pin, :unpin, :mark_as_key_opinion, :unmark_as_key_opinion]

  def create
    @commentable = find_commentable
    @comment = @commentable.comments.new(comment_params)

    # Set author info based on current user
    if current_lawyer
      @comment.author = current_lawyer
      @comment.author_name = current_lawyer.display_name
      @comment.author_role = current_lawyer.role # 'lawyer' or 'assistant'
    elsif current_company_user
      @comment.author = current_company_user
      @comment.author_name = current_company_user.display_name
      @comment.author_role = current_company_user.role # 'boss', 'employee', 'hr'
    end
    
    # Handle mentioned_user_ids from form checkboxes
    if params[:comment][:mentioned_user_ids].present?
      mentioned_ids = params[:comment][:mentioned_user_ids].reject(&:blank?).map do |json_string|
        JSON.parse(json_string)
      end
      @comment.mentioned_user_ids = mentioned_ids if mentioned_ids.any?
    end

    if @comment.save
      redirect_back fallback_location: root_path, notice: '意见已提交'
    else
      redirect_back fallback_location: root_path, alert: "提交失败：#{@comment.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    if @comment.deletable_by?(current_user || current_lawyer)
      @comment.destroy
      redirect_back fallback_location: root_path, notice: '意见已删除'
    else
      redirect_back fallback_location: root_path, alert: '无法删除：仅30分钟内可删除自己的意见'
    end
  end

  # 追加附件到已有的评论
  def append_attachments
    if params[:attachments].present?
      params[:attachments].each do |attachment|
        @comment.attachments.attach(attachment) if attachment.present?
      end
      redirect_back fallback_location: root_path, notice: '附件已添加'
    else
      redirect_back fallback_location: root_path, alert: '请选择要添加的附件'
    end
  end
  
  # 置顶评论
  def pin
    current_actor = current_lawyer || current_company_user
    
    if current_actor.nil?
      redirect_back fallback_location: root_path, alert: "无权操作" and return
    end
    
    @comment.pin!(current_actor)
    redirect_back fallback_location: root_path, notice: "✅ 评论已置顶"
  end
  
  # 取消置顶
  def unpin
    @comment.unpin!
    redirect_back fallback_location: root_path, notice: "✅ 已取消置顶"
  end
  
  # 标记为关键意见
  def mark_as_key_opinion
    @comment.mark_as_key_opinion!
    redirect_back fallback_location: root_path, notice: "✅ 已标记为关键意见"
  end
  
  # 取消关键意见标记
  def unmark_as_key_opinion
    @comment.unmark_as_key_opinion!
    redirect_back fallback_location: root_path, notice: "✅ 已取消关键意见标记"
  end

  private

  def require_authentication
    unless current_user || current_lawyer
      redirect_to login_path, alert: '请先登录'
    end
  end

  def find_commentable
    # 从参数中获取评论对象类型和ID
    if params[:commentable_type].present? && params[:commentable_id].present?
      params[:commentable_type].constantize.find(params[:commentable_id])
    else
      # 尝试从嵌套路由中获取
      if params[:contract_id].present?
        Contract.find(params[:contract_id])
      elsif params[:case_id].present?
        Case.find(params[:case_id])
      elsif params[:major_issue_id].present?
        MajorIssue.find(params[:major_issue_id])
      elsif params[:reconciliation_id].present?
        Reconciliation.find(params[:reconciliation_id])
      else
        raise "无法确定评论对象"
      end
    end
  end

  def set_comment
    @comment = Comment.find(params[:id])
    
    # 🔒 安全检查：企业用户只能访问自己公司相关资源的评论
    if current_company_user
      commentable = @comment.commentable
      
      # 检查评论所属资源是否属于当前用户的公司
      if commentable.respond_to?(:company_id)
        unless commentable.company_id == current_company_user.company_id
          raise ActiveRecord::RecordNotFound, "Comment not found or access denied"
        end
      end
    end
  end

  def comment_params
    params.require(:comment).permit(:content, :visibility, attachments: [])
  end
end
