class EnhanceWorkLogsForStructuredTracking < ActiveRecord::Migration[7.2]
  def change
    # 添加工作记录类型和待办事项相关字段
    add_column :work_logs, :log_type, :string, default: 'general'
    add_column :work_logs, :is_todo, :boolean, default: false
    add_column :work_logs, :todo_status, :string
    add_column :work_logs, :due_date, :date
    add_column :work_logs, :reminder_at, :datetime
    add_column :work_logs, :completed_at, :datetime
    add_column :work_logs, :is_important, :boolean, default: false
    add_column :work_logs, :assigned_to_id, :integer
    add_column :work_logs, :assigned_to_type, :string
    
    # 添加索引
    add_index :work_logs, :log_type
    add_index :work_logs, :is_todo
    add_index :work_logs, :todo_status
    add_index :work_logs, :due_date
    add_index :work_logs, [:assigned_to_type, :assigned_to_id]
  end
end
