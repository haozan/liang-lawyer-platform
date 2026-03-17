class AddLawyerReviewFieldsToReconciliations < ActiveRecord::Migration[7.2]
  def change
    add_column :reconciliations, :reviewed_by_lawyer, :boolean, default: false
    add_column :reconciliations, :reviewed_at, :datetime
    add_column :reconciliations, :reviewed_by_lawyer_id, :integer
    
    add_index :reconciliations, :reviewed_by_lawyer
    add_index :reconciliations, :reviewed_by_lawyer_id
  end
end
