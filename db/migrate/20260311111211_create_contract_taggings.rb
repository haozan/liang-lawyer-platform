class CreateContractTaggings < ActiveRecord::Migration[7.2]
  def change
    create_table :contract_taggings do |t|
      t.integer :contract_id
      t.integer :tag_id


      t.timestamps
    end
  end
end
