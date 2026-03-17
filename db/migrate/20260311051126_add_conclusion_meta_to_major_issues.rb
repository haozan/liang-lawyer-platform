class AddConclusionMetaToMajorIssues < ActiveRecord::Migration[7.2]
  def change
    add_column :major_issues, :conclusion_updated_at, :datetime
    add_column :major_issues, :conclusion_updated_by_id, :integer
    add_column :major_issues, :conclusion_updated_by_type, :string
    
    add_index :major_issues, [:conclusion_updated_by_type, :conclusion_updated_by_id], name: 'index_major_issues_on_conclusion_updater'
  end
end
