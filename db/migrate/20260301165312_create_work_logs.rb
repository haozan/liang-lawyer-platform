class CreateWorkLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :work_logs do |t|
      t.references :case
      t.date :date
      t.string :title
      t.text :content


      t.timestamps
    end
  end
end
