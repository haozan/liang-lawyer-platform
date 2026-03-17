class CreateDataAccessLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :data_access_logs do |t|
      t.integer :lawyer_id
      t.string :resource_type
      t.integer :resource_id
      t.string :action
      t.string :access_method
      t.string :ip_address

      t.index :lawyer_id
      t.index [:resource_type, :resource_id]
      t.index :created_at

      t.timestamps
    end
  end
end
