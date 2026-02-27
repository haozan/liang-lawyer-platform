class CreateRegulations < ActiveRecord::Migration[7.2]
  def change
    create_table :regulations do |t|
      t.references :company
      t.string :name
      t.string :file


      t.timestamps
    end
  end
end
