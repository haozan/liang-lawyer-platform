class RefactorAccountSystem < ActiveRecord::Migration[7.2]
  def up
    # =========================================================
    # 1. 新建 company_memberships 关联表（CompanyUser ↔ Company）
    # =========================================================
    create_table :company_memberships do |t|
      t.references :company, null: false, foreign_key: true, index: true
      t.references :company_user, null: false, foreign_key: true, index: true
      t.string :role, null: false, default: 'employee'
      t.timestamps
    end
    add_index :company_memberships, [:company_id, :company_user_id], unique: true, name: 'index_company_memberships_unique'

    # =========================================================
    # 2. 迁移 company_users 已有数据到 company_memberships
    # =========================================================
    execute <<~SQL
      INSERT INTO company_memberships (company_id, company_user_id, role, created_at, updated_at)
      SELECT company_id, id, role, NOW(), NOW()
      FROM company_users
      WHERE company_id IS NOT NULL
    SQL

    # =========================================================
    # 3. company_users 表：phone 改为全局唯一，删除 company_id / role
    # =========================================================
    # 先删旧的唯一索引 (company_id, phone)
    remove_index :company_users, name: 'index_company_users_on_company_id_and_phone'
    remove_index :company_users, name: 'index_company_users_on_company_id' if index_exists?(:company_users, :company_id)

    # phone 改为全局唯一
    add_index :company_users, :phone, unique: true, name: 'index_company_users_on_phone'

    # 删除 company_id 和 role 字段
    remove_column :company_users, :company_id
    remove_column :company_users, :role

    # =========================================================
    # 4. lawyer_accounts 表：删除团队相关字段，简化 role
    # =========================================================
    # 先将旧角色映射到新角色
    execute <<~SQL
      UPDATE lawyer_accounts
      SET role = CASE
        WHEN role IN ('super_admin') THEN 'admin'
        WHEN role IN ('team_leader', 'senior_lawyer', 'lawyer') THEN 'lawyer'
        WHEN role = 'assistant' THEN 'assistant'
        ELSE 'lawyer'
      END
    SQL

    # 删除团队字段
    remove_column :lawyer_accounts, :lawyer_team_id if column_exists?(:lawyer_accounts, :lawyer_team_id)
    remove_column :lawyer_accounts, :can_view_cross_team if column_exists?(:lawyer_accounts, :can_view_cross_team)

    # =========================================================
    # 5. companies 表：删除团队相关字段
    # =========================================================
    remove_column :companies, :lawyer_team_id if column_exists?(:companies, :lawyer_team_id)
    remove_column :companies, :suspended_by_id if column_exists?(:companies, :suspended_by_id)

    # =========================================================
    # 6. 删除团队系统相关表
    # =========================================================
    drop_table :business_team_ownerships, if_exists: true
    drop_table :company_team_accesses, if_exists: true
    drop_table :lawyer_business_accesses, if_exists: true
    drop_table :data_access_logs, if_exists: true
    drop_table :lawyer_teams, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "此迁移不可回滚，请从备份恢复"
  end
end
