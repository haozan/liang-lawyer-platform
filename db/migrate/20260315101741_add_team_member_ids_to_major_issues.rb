class AddTeamMemberIdsToMajorIssues < ActiveRecord::Migration[7.2]
  def change
    add_column :major_issues, :team_member_ids, :text
    add_index :major_issues, :team_member_ids
  end
end
