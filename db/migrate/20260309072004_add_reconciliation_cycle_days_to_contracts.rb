class AddReconciliationCycleDaysToContracts < ActiveRecord::Migration[7.2]
  def change
    add_column :contracts, :reconciliation_cycle_days, :integer

  end
end
