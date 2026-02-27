class CreateReconciliations < ActiveRecord::Migration[7.2]
  def change
    create_table :reconciliations do |t|
      t.references :contract
      t.string :period
      t.string :uploaded_by
      t.datetime :uploaded_at
      t.text :notes


      t.timestamps
    end
  end
end
