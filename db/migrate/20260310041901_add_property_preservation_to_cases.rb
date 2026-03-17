class AddPropertyPreservationToCases < ActiveRecord::Migration[7.2]
  def change
    add_column :cases, :property_preservation_applied_at, :date
    add_column :cases, :property_preservation_deadline, :date
    add_column :cases, :property_preservation_history, :text

  end
end
