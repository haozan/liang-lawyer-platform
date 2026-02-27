class CreateCompanyUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :company_users do |t|
      t.references :company
      t.string :email
      t.string :password_digest
      t.string :name
      t.string :role, default: "hr"


      t.timestamps
    end
  end
end
