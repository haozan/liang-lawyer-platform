class SavedFiltersController < ApplicationController
  before_action :require_authentication
  before_action :set_saved_filter, only: [:update, :destroy]

  def index
    current_actor = current_lawyer || current_company_user
    
    if current_actor.nil?
      redirect_to login_path, alert: "请先登录" and return
    end
    
    # 获取当前用户的所有保存的筛选条件
    @saved_filters = SavedFilter.where(
      user_type: current_actor.class.name,
      user_id: current_actor.id,
      filterable_type: params[:filterable_type] || 'MajorIssue'
    ).order(created_at: :desc)
  end

  def create
    current_actor = current_lawyer || current_company_user
    
    if current_actor.nil?
      redirect_back fallback_location: root_path, alert: "请先登录" and return
    end
    
    @saved_filter = SavedFilter.new(saved_filter_params)
    @saved_filter.user_type = current_actor.class.name
    @saved_filter.user_id = current_actor.id

    if @saved_filter.save
      redirect_back fallback_location: root_path, notice: "✅ 筛选条件已保存"
    else
      redirect_back fallback_location: root_path, alert: "保存失败：#{@saved_filter.errors.full_messages.join(', ')}"
    end
  end

  def update
    if @saved_filter.update(saved_filter_params)
      redirect_back fallback_location: root_path, notice: "✅ 筛选条件已更新"
    else
      redirect_back fallback_location: root_path, alert: "更新失败：#{@saved_filter.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @saved_filter.destroy
    redirect_back fallback_location: root_path, notice: "✅ 筛选条件已删除"
  end

  private

  def require_authentication
    unless current_user || current_lawyer
      redirect_to login_path, alert: '请先登录'
    end
  end

  def set_saved_filter
    current_actor = current_lawyer || current_company_user
    
    @saved_filter = SavedFilter.find_by(
      id: params[:id],
      user_type: current_actor.class.name,
      user_id: current_actor.id
    )
    
    unless @saved_filter
      redirect_back fallback_location: root_path, alert: "未找到筛选条件"
    end
  end

  def saved_filter_params
    params.require(:saved_filter).permit(
      :name,
      :filterable_type,
      :is_default,
      conditions: {}
    )
  end
end
