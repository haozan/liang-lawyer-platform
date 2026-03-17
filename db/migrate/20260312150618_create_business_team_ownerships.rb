class CreateBusinessTeamOwnerships < ActiveRecord::Migration[7.2]
  def change
    create_table :business_team_ownerships do |t|
      t.string :business_type
      t.integer :business_id
      t.integer :lawyer_team_id
      t.integer :company_id
      t.boolean :is_primary, default: false
      t.string :access_level
      t.integer :authorized_by_id
      t.datetime :authorized_at
      t.datetime :expires_at

      t.index :lawyer_team_id
      t.index :company_id
      t.index [:business_type, :business_id]
      t.index [:business_type, :business_id, :lawyer_team_id], name: 'index_bto_on_business_and_team', unique: true

      t.timestamps
    end
  end
end
