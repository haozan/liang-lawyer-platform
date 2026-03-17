class CreateAnnouncements < ActiveRecord::Migration[7.2]
  def change
    create_table :announcements do |t|
      t.string :title, null: false
      t.text :content
      t.string :announcement_type, null: false # hearing/contract_expiry/contract_review/reconciliation_overdue/custom
      t.string :priority, null: false, default: 'normal' # urgent/important/normal
      t.bigint :company_id # nil = 全局公告（所有企业可见）
      t.string :related_type # 多态关联：Contract/Case/Reconciliation/MajorIssue
      t.bigint :related_id
      t.datetime :expires_at # 过期时间，nil = 永不过期
      t.datetime :published_at # 发布时间
      t.string :created_by_type # LawyerAccount/System
      t.bigint :created_by_id

      t.timestamps
    end
    
    add_index :announcements, :company_id
    add_index :announcements, [:related_type, :related_id]
    add_index :announcements, :announcement_type
    add_index :announcements, :priority
    add_index :announcements, :published_at
    
    # 已读状态表（仅用于手动公告）
    create_table :announcement_read_statuses do |t|
      t.bigint :announcement_id, null: false
      t.string :user_type, null: false # CompanyUser/LawyerAccount
      t.bigint :user_id, null: false
      t.datetime :read_at, null: false
      
      t.timestamps
    end
    
    add_index :announcement_read_statuses, :announcement_id
    add_index :announcement_read_statuses, [:user_type, :user_id]
    add_index :announcement_read_statuses, [:announcement_id, :user_type, :user_id], unique: true, name: 'index_announcement_read_unique'
  end
end
