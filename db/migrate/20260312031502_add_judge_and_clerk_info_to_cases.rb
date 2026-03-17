class AddJudgeAndClerkInfoToCases < ActiveRecord::Migration[7.2]
  def change
    add_column :cases, :judge_name, :string
    add_column :cases, :judge_phone, :string
    add_column :cases, :clerk_name, :string
    add_column :cases, :clerk_phone, :string

  end
end
