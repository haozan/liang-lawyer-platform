class AddTeamFieldsToLawyerAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :lawyer_accounts, :lawyer_team_id, :integer
    add_column :lawyer_accounts, :can_view_cross_team, :boolean, default: false

    add_index :lawyer_accounts, :lawyer_team_id
  end
end
