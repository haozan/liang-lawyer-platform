class AddLawyerReviewFieldsToMajorIssues < ActiveRecord::Migration[7.2]
  def change
    add_column :major_issues, :reviewed_by_lawyer, :boolean, default: false
    add_column :major_issues, :reviewed_at, :datetime
    add_column :major_issues, :reviewed_by_lawyer_id, :integer
    
    add_index :major_issues, :reviewed_by_lawyer
    add_index :major_issues, :reviewed_by_lawyer_id
  end
end
