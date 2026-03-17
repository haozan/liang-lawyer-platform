class ChangeEmailToPhoneInLawyerAccounts < ActiveRecord::Migration[7.2]
  def change
    # Remove email column and its index
    remove_index :lawyer_accounts, :email
    remove_column :lawyer_accounts, :email, :string
    
    # Add phone column with unique index
    add_column :lawyer_accounts, :phone, :string
    add_index :lawyer_accounts, :phone, unique: true
  end
end
