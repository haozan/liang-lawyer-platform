class SearchesController < ApplicationController
  def index
    @query = params[:q]&.strip
    @category = params[:category]
    
    if @query.present?
      # 根据用户类型确定可搜索企业范围（权限隔离核心逻辑）
      company_ids = if lawyer?
        Company.pluck(:id)  # 律师可搜索所有企业
      else
        [current_company_user.company_id]  # 企业用户只能搜索自己企业
      end
      
      @results = SearchIndex.search(
        query: @query,
        company_ids: company_ids,
        categories: @category,
        page: params[:page] || 1
      )
      
      # 按分类统计
      @stats = SearchIndex.category_stats(
        query: @query,
        company_ids: company_ids
      )
    else
      @results = SearchIndex.none.page(1)
      @stats = {}
    end
  end
end
