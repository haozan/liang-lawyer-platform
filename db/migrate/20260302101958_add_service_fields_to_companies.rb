class AddServiceFieldsToCompanies < ActiveRecord::Migration[7.2]
  def change
    add_column :companies, :status, :string, default: 'active', null: false
    add_column :companies, :service_expires_at, :date
    add_column :companies, :suspended_at, :datetime
    add_column :companies, :suspended_reason, :text
    add_column :companies, :suspended_by_id, :integer
    
    add_index :companies, :status
    add_index :companies, :service_expires_at
  end
end
