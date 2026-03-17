class CreateLawyerTeams < ActiveRecord::Migration[7.2]
  def change
    create_table :lawyer_teams do |t|
      t.string :name
      t.string :code
      t.integer :leader_id
      t.string :data_isolation_level, default: "flexible"
      t.string :status, default: "active"

      t.index :code, unique: true

      t.timestamps
    end
  end
end
