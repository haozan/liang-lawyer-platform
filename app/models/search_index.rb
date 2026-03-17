class SearchIndex < ApplicationRecord
  self.table_name = 'search_indexes'
  
  belongs_to :searchable, polymorphic: true
  belongs_to :company
  
  # 搜索方法
  def self.search(query:, company_ids:, categories: nil, page: 1, per_page: 20)
    return none if query.blank?
    
    results = where(company_id: company_ids)
    results = results.where(category: categories) if categories.present?
    
    # 使用 pg_trgm 相似度搜索
    sanitized_query = sanitize_sql_like(query)
    results = results.where(
      "title ILIKE ? OR content ILIKE ?",
      "%#{sanitized_query}%",
      "%#{sanitized_query}%"
    )
    
    # 按相关度排序（标题匹配优先）
    results = results.select(
      "search_indexes.*",
      "similarity(title, #{connection.quote(query)}) AS title_similarity",
      "similarity(COALESCE(content, ''), #{connection.quote(query)}) AS content_similarity"
    ).order("title_similarity DESC, content_similarity DESC, indexed_at DESC")
    
    results.page(page).per(per_page)
  end
  
  # 按分类统计
  def self.category_stats(query:, company_ids:)
    return {} if query.blank?
    
    sanitized_query = sanitize_sql_like(query)
    where(company_id: company_ids)
      .where("title ILIKE ? OR content ILIKE ?", "%#{sanitized_query}%", "%#{sanitized_query}%")
      .group(:category)
      .count
  end
end
