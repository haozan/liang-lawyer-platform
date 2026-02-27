class CreateEmployees < ActiveRecord::Migration[7.2]
  def change
    create_table :employees do |t|
      t.references :company
      t.string :name
      t.string :gender
      t.string :id_number
      t.string :position
      t.decimal :salary
      t.date :hired_at
      t.date :probation_end_at
      t.date :social_insurance_at
      t.date :contract_signed_at
      t.date :contract_end_at


      t.timestamps
    end
  end
end
