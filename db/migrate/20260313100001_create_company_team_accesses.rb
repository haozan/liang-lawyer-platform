class CreateCompanyTeamAccesses < ActiveRecord::Migration[7.2]
  def change
    create_table :company_team_accesses do |t|
      t.integer :company_id, null: false
      t.integer :lawyer_team_id, null: false
      t.string :access_level, default: 'viewer', null: false  # viewer/editor/manager
      t.integer :authorized_by_id  # 授权人ID（团队负责人）
      t.datetime :authorized_at
      t.datetime :expires_at  # 授权到期时间（可选）
      t.text :notes  # 授权备注

      t.timestamps
    end

    add_index :company_team_accesses, [:company_id, :lawyer_team_id], unique: true, name: 'index_company_team_accesses_unique'
    add_index :company_team_accesses, :company_id
    add_index :company_team_accesses, :lawyer_team_id
    add_index :company_team_accesses, :authorized_by_id
    
    add_foreign_key :company_team_accesses, :companies
    add_foreign_key :company_team_accesses, :lawyer_teams
    add_foreign_key :company_team_accesses, :lawyer_accounts, column: :authorized_by_id
  end
end
