class CreateMajorIssueFollowersAndReadStatuses < ActiveRecord::Migration[7.2]
  def change
    # 关注功能
    create_table :major_issue_followers do |t|
      t.references :major_issue, foreign_key: true, null: false
      t.references :user, polymorphic: true, null: false, index: true
      t.boolean :notify_new_comment, default: true
      t.boolean :notify_status_change, default: true
      
      t.timestamps
    end
    
    add_index :major_issue_followers, [:major_issue_id, :user_type, :user_id], 
              unique: true, 
              name: 'index_followers_on_issue_and_user'
    
    # 阅读状态
    create_table :major_issue_read_statuses do |t|
      t.references :major_issue, foreign_key: true, null: false
      t.references :user, polymorphic: true, null: false, index: true
      t.datetime :last_read_at
      t.integer :last_read_comment_id
      t.integer :unread_count, default: 0
      
      t.timestamps
    end
    
    add_index :major_issue_read_statuses, [:major_issue_id, :user_type, :user_id], 
              unique: true, 
              name: 'index_read_statuses_on_issue_and_user'
    add_index :major_issue_read_statuses, :unread_count
  end
end
