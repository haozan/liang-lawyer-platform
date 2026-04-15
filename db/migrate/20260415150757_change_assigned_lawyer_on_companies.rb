class ChangeAssignedLawyerOnCompanies < ActiveRecord::Migration[7.2]
  def change
    remove_index :companies, :assigned_lawyer_id
    remove_column :companies, :assigned_lawyer_id, :integer

    add_column :companies, :assigned_lawyer_ids, :integer, array: true, default: []
    add_index :companies, :assigned_lawyer_ids, using: :gin
  end
end
