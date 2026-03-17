# Concern for models that need to be searchable
# Automatically updates SearchIndex when record is created/updated/destroyed
module Searchable
  extend ActiveSupport::Concern
  
  included do
    after_commit :update_search_index, on: [:create, :update]
    after_commit :remove_search_index, on: :destroy
  end
  
  def update_search_index
    SearchIndex.find_or_initialize_by(
      searchable_type: self.class.name,
      searchable_id: id
    ).update!(
      company_id: search_company_id,
      title: search_title,
      content: search_content,
      category: search_category,
      metadata: search_metadata,
      indexed_at: Time.current
    )
  rescue => e
    Rails.logger.error("Failed to update search index for #{self.class.name}##{id}: #{e.message}")
  end
  
  def remove_search_index
    SearchIndex.where(searchable_type: self.class.name, searchable_id: id).destroy_all
  rescue => e
    Rails.logger.error("Failed to remove search index for #{self.class.name}##{id}: #{e.message}")
  end
  
  # 子类需要实现的方法
  def search_company_id
    raise NotImplementedError, "#{self.class.name} must implement #search_company_id"
  end
  
  def search_title
    raise NotImplementedError, "#{self.class.name} must implement #search_title"
  end
  
  def search_content
    ""
  end
  
  def search_category
    self.class.name
  end
  
  def search_metadata
    {}
  end
end
