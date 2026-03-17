class AddLockableToLawyerAccountsAndCompanyUsers < ActiveRecord::Migration[7.2]
  def change
    # Add lockable fields to lawyer_accounts
    add_column :lawyer_accounts, :failed_attempts, :integer, default: 0, null: false
    add_column :lawyer_accounts, :unlock_token, :string
    add_column :lawyer_accounts, :locked_at, :datetime
    add_index :lawyer_accounts, :unlock_token, unique: true
    
    # Add lockable fields to company_users
    add_column :company_users, :failed_attempts, :integer, default: 0, null: false
    add_column :company_users, :unlock_token, :string
    add_column :company_users, :locked_at, :datetime
    add_index :company_users, :unlock_token, unique: true
  end
end
