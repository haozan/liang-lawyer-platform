class AddAssignedLawyerToCompanies < ActiveRecord::Migration[7.2]
  def change
    add_column :companies, :assigned_lawyer_id, :integer
    add_index :companies, :assigned_lawyer_id
  end
end
