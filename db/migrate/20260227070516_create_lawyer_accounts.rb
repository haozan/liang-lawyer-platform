class CreateLawyerAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :lawyer_accounts do |t|
      t.string :email
      t.string :password_digest
      t.string :name

      t.index :email, unique: true

      t.timestamps
    end
  end
end
