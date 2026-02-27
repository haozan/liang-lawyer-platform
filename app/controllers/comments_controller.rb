class CommentsController < ApplicationController
  def create
    @commentable = find_commentable
    @comment = @commentable.comments.new(comment_params)
    
    # Set author info based on current user
    if lawyer?
      @comment.author_name = "律师团队"
      @comment.author_role = "lawyer"
    elsif current_company_user
      @comment.author_name = current_company_user.display_name
      @comment.author_role = current_company_user.role
    end
    
    if @comment.save
      redirect_back fallback_location: root_path, notice: "评论已发布"
    else
      redirect_back fallback_location: root_path, alert: @comment.errors.full_messages.join(", ")
    end
  end

  private

  def find_commentable
    if params[:employee_id]
      Employee.find(params[:employee_id])
    elsif params[:contract_id]
      Contract.find(params[:contract_id])
    elsif params[:regulation_id]
      Regulation.find(params[:regulation_id])
    end
  end

  def comment_params
    params.require(:comment).permit(:content, attachments: [])
  end
end
