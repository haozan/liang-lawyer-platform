class CreateLawyerBusinessAccesses < ActiveRecord::Migration[7.2]
  def change
    create_table :lawyer_business_accesses do |t|
      t.integer :lawyer_id
      t.string :business_type
      t.integer :business_id
      t.string :access_level
      t.text :reason
      t.integer :authorized_by_id
      t.datetime :expires_at

      t.index :lawyer_id
      t.index [:business_type, :business_id]
      t.index [:lawyer_id, :business_type, :business_id], name: 'index_lba_on_lawyer_and_business', unique: true

      t.timestamps
    end
  end
end
