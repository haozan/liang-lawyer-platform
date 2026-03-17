class EnhanceMajorIssues < ActiveRecord::Migration[7.2]
  def change
    # 决策结论
    add_column :major_issues, :conclusion, :text
    
    # 进度追踪
    add_column :major_issues, :processing_days, :integer, default: 0
    add_index :major_issues, :processing_days
    
    # 统计字段
    add_column :major_issues, :followers_count, :integer, default: 0
    add_column :major_issues, :views_count, :integer, default: 0
    add_column :major_issues, :comments_count, :integer, default: 0
    
    # 关联其他模块
    add_column :major_issues, :related_record_type, :string
    add_column :major_issues, :related_record_id, :integer
    add_index :major_issues, [:related_record_type, :related_record_id]
    
    # 外部分享
    add_column :major_issues, :share_token, :string
    add_column :major_issues, :share_expires_at, :datetime
    add_index :major_issues, :share_token, unique: true
    
    # 状态变更时间戳
    add_column :major_issues, :discussing_at, :datetime
    add_column :major_issues, :archived_at, :datetime
  end
end
