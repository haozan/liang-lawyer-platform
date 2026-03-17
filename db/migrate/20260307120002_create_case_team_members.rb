class CreateCaseTeamMembers < ActiveRecord::Migration[7.2]
  def change
    create_table :case_team_members do |t|
      t.bigint :case_id, null: false
      t.bigint :lawyer_account_id, null: false
      t.string :role, null: false
      t.datetime :joined_at, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    add_index :case_team_members, :case_id
    add_index :case_team_members, :lawyer_account_id
    add_index :case_team_members, :role
    add_index :case_team_members, [:case_id, :lawyer_account_id], unique: true, name: 'index_case_team_on_case_and_lawyer'
    
    add_foreign_key :case_team_members, :cases
    add_foreign_key :case_team_members, :lawyer_accounts
  end
end
