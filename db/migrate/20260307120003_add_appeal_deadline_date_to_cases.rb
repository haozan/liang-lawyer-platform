class AddAppealDeadlineDateToCases < ActiveRecord::Migration[7.2]
  def change
    add_column :cases, :appeal_deadline_date, :date
    add_index :cases, :appeal_deadline_date
  end
end
