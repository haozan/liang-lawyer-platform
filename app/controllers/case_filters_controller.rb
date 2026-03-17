class CaseFiltersController < ApplicationController
  before_action :require_authentication
  before_action :set_case_filter, only: [:update, :destroy, :set_as_default]
  
  def create
    @case_filter = current_user.case_filters.new(case_filter_params)
    
    if @case_filter.save
      render json: { success: true, message: '筛选条件已保存' }, status: :created
    else
      render json: { success: false, errors: @case_filter.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def update
    if @case_filter.update(case_filter_params)
      render json: { success: true, message: '筛选条件已更新' }
    else
      render json: { success: false, errors: @case_filter.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  def destroy
    @case_filter.destroy
    redirect_to cases_path, notice: '筛选条件已删除'
  end
  
  def set_as_default
    @case_filter.set_as_default!
    redirect_to cases_path, notice: '已设为默认筛选条件'
  end
  
  private
  
  def set_case_filter
    @case_filter = current_user.case_filters.find(params[:id])
  end
  
  def case_filter_params
    params.require(:case_filter).permit(:name, :is_default, filter_params: {})
  end
end
