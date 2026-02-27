class CreateContracts < ActiveRecord::Migration[7.2]
  def change
    create_table :contracts do |t|
      t.references :company
      t.string :name
      t.date :signed_at
      t.date :end_at
      t.string :status, default: "active"
      t.string :file


      t.timestamps
    end
  end
end
