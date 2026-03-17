class CreateSearchIndexes < ActiveRecord::Migration[7.2]
  def change
    # 启用 PostgreSQL 扩展（支持中文搜索）
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')
    enable_extension 'unaccent' unless extension_enabled?('unaccent')
    
    create_table :search_indexes do |t|
      t.string :searchable_type, null: false  # 多态类型（Contract/Case/等）
      t.bigint :searchable_id, null: false    # 记录 ID
      t.bigint :company_id, null: false       # 企业 ID（权限隔离关键字段）
      t.string :title, null: false            # 标题（主要搜索字段）
      t.text :content                         # 内容（次要搜索字段）
      t.string :category                      # 分类（合同/案件/问题等）
      t.jsonb :metadata, default: {}          # 扩展元数据（状态/日期等）
      t.datetime :indexed_at                  # 索引更新时间
      t.timestamps
    end
    
    # 复合索引（性能关键）
    add_index :search_indexes, [:searchable_type, :searchable_id], unique: true, name: 'index_search_on_searchable'
    add_index :search_indexes, :company_id
    
    # GIN 索引（全文搜索核心）
    add_index :search_indexes, :title, using: :gin, opclass: :gin_trgm_ops
    add_index :search_indexes, :content, using: :gin, opclass: :gin_trgm_ops
    
    # 分类索引
    add_index :search_indexes, :category
  end
end
