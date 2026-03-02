class AddStageToCases < ActiveRecord::Migration[7.2]
  def change
    add_column :cases, :stage, :string
    add_index :cases, :stage
  end
end
