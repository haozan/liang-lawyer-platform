class CreateContractTags < ActiveRecord::Migration[7.2]
  def change
    create_table :contract_tags do |t|
      t.string :name
      t.string :color, default: "#3B82F6"
      t.integer :company_id


      t.timestamps
    end
  end
end
