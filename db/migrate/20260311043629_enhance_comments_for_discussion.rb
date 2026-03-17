class EnhanceCommentsForDiscussion < ActiveRecord::Migration[7.2]
  def change
    # 添加polymorphic author支持（保留原有author_name和author_role作为快照）
    add_column :comments, :author_id, :integer
    add_column :comments, :author_type, :string
    add_index :comments, [:author_type, :author_id]
    
    # @提醒功能
    add_column :comments, :mentioned_user_ids, :jsonb, default: []
    add_index :comments, :mentioned_user_ids, using: :gin
    
    # 置顶功能
    add_column :comments, :is_pinned, :boolean, default: false
    add_column :comments, :pinned_at, :datetime
    add_column :comments, :pinned_by_id, :integer
    add_column :comments, :pinned_by_type, :string
    add_index :comments, :is_pinned
    add_index :comments, [:pinned_by_type, :pinned_by_id]
    
    # 关键意见标记
    add_column :comments, :is_key_opinion, :boolean, default: false
    add_index :comments, :is_key_opinion
  end
end
