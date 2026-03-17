class AddPerformanceIndexes < ActiveRecord::Migration[7.2]
  def change
    # Cases table - 案件列表和查询优化
    add_index :cases, [:company_id, :status, :filing_at], name: 'idx_cases_company_status_filing'
    add_index :cases, [:company_id, :priority, :last_activity_at], name: 'idx_cases_company_priority_activity'
    
    # Contracts table - 合同列表和查询优化
    add_index :contracts, [:company_id, :status, :signed_at], name: 'idx_contracts_company_status_signed'
    add_index :contracts, [:company_id, :end_at], name: 'idx_contracts_company_end_at'
    
    # Major issues table - 重大事项列表优化
    add_index :major_issues, [:company_id, :status, :priority], name: 'idx_major_issues_company_status_priority'
    add_index :major_issues, [:company_id, :created_at], name: 'idx_major_issues_company_created_at'
    
    # Comments table - 评论多态查询优化
    add_index :comments, [:commentable_type, :commentable_id, :created_at], name: 'idx_comments_polymorphic_created'
    
    # Case team members - 案件团队查询优化
    add_index :case_team_members, [:lawyer_account_id, :case_id], name: 'idx_case_team_lawyer_case', 
              where: "lawyer_account_id IS NOT NULL"
    
    # Announcements - 公告查询优化
    add_index :announcements, [:company_id, :published_at, :announcement_type], 
              name: 'idx_announcements_company_published_type'
    
    # Case notifications - 通知查询优化
    add_index :case_notifications, [:recipient_type, :recipient_id, :read_at], 
              name: 'idx_case_notifications_recipient_read'
  end
end
