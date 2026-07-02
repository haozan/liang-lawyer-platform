class DropUnusedTables < ActiveRecord::Migration[7.2]
  def up
    # === 案件辅助表 ===
    drop_table :case_filters, if_exists: true
    drop_table :case_notifications, if_exists: true
    drop_table :case_progress_events, if_exists: true
    drop_table :case_questions, if_exists: true
    drop_table :case_relations, if_exists: true
    drop_table :case_series_memberships, if_exists: true
    drop_table :case_series, if_exists: true
    drop_table :case_weekly_reports, if_exists: true
    drop_table :case_clients, if_exists: true

    # === 公告辅助表（简化为单表） ===
    drop_table :announcement_groups, if_exists: true
    drop_table :announcement_dismissals, if_exists: true
    drop_table :announcement_read_statuses, if_exists: true

    # === 合同标签 ===
    drop_table :contract_tags, if_exists: true
    drop_table :contract_taggings, if_exists: true

    # === 重大事项辅助表 ===
    drop_table :major_issue_followers, if_exists: true
    drop_table :major_issue_read_statuses, if_exists: true
    drop_table :major_issue_todo_items, if_exists: true

    # === 其他 ===
    drop_table :friendly_id_slugs, if_exists: true
    # company_memberships 保留（企业用户↔公司多对多关系）
    drop_table :admin_oplogs, if_exists: true
    drop_table :search_indexes, if_exists: true
  end

  def down
    # 这些表不再需要，不提供回滚
    raise ActiveRecord::IrreversibleMigration
  end
end
