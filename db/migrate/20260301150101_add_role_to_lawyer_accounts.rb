class AddRoleToLawyerAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :lawyer_accounts, :role, :string, default: 'lawyer'
    add_index :lawyer_accounts, :role
  end
end
