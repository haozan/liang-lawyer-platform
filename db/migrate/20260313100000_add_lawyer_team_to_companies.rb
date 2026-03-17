class AddLawyerTeamToCompanies < ActiveRecord::Migration[7.2]
  def change
    add_column :companies, :lawyer_team_id, :integer
    add_index :companies, :lawyer_team_id
    add_foreign_key :companies, :lawyer_teams, column: :lawyer_team_id
  end
end
