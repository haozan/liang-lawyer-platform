class AddSubmitterToWorkLogs < ActiveRecord::Migration[7.2]
  def change
    add_reference :work_logs, :submitter, polymorphic: true, null: true
  end
end
