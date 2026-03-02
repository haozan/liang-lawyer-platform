class ChangeEmailToPhoneInCompanyUsers < ActiveRecord::Migration[7.2]
  def up
    # Add phone column
    add_column :company_users, :phone, :string
    
    # Migrate existing email data to phone (if any)
    # This assumes emails might be used as phone numbers temporarily
    execute <<-SQL
      UPDATE company_users 
      SET phone = email 
      WHERE email IS NOT NULL
    SQL
    
    # Remove email unique index
    remove_index :company_users, name: "index_company_users_on_company_id_and_email" if index_exists?(:company_users, [:company_id, :email], name: "index_company_users_on_company_id_and_email")
    
    # Remove email column
    remove_column :company_users, :email
    
    # Add unique index for phone scoped to company
    add_index :company_users, [:company_id, :phone], unique: true
  end
  
  def down
    # Add email column back
    add_column :company_users, :email, :string
    
    # Migrate phone data back to email
    execute <<-SQL
      UPDATE company_users 
      SET email = phone 
      WHERE phone IS NOT NULL
    SQL
    
    # Remove phone index
    remove_index :company_users, [:company_id, :phone]
    
    # Remove phone column
    remove_column :company_users, :phone
    
    # Add email unique index back
    add_index :company_users, [:company_id, :email], unique: true
  end
end
