class DropEmployeesAndRegulations < ActiveRecord::Migration[7.2]
  def change
    drop_table :employees, if_exists: true do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name
      t.string :employee_number
      t.string :department
      t.string :position
      t.string :employment_type
      t.date :hire_date
      t.date :termination_date
      t.string :status
      t.text :notes
      t.timestamps
    end
    
    drop_table :regulations, if_exists: true do |t|
      t.references :company, null: false, foreign_key: true
      t.string :title
      t.string :category
      t.date :effective_date
      t.string :status
      t.text :summary
      t.timestamps
    end
  end
end
