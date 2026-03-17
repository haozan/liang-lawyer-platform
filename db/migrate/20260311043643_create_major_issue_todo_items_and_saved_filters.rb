class CreateMajorIssueTodoItemsAndSavedFilters < ActiveRecord::Migration[7.2]
  def change
    # 待办事项
    create_table :major_issue_todo_items do |t|
      t.references :major_issue, foreign_key: true, null: false
      t.string :title, null: false
      t.text :description
      t.string :status, default: 'pending'
      t.references :assignee, polymorphic: true, index: true
      t.references :creator, polymorphic: true, index: true
      t.date :due_date
      t.datetime :completed_at
      t.integer :completed_by_id
      t.string :completed_by_type
      
      t.timestamps
    end
    
    add_index :major_issue_todo_items, :status
    add_index :major_issue_todo_items, :due_date
    add_index :major_issue_todo_items, [:completed_by_type, :completed_by_id]
    
    # 保存的筛选条件
    create_table :saved_filters do |t|
      t.references :user, polymorphic: true, null: false, index: true
      t.string :name, null: false
      t.jsonb :conditions, default: {}
      t.string :filterable_type, null: false
      t.boolean :is_default, default: false
      
      t.timestamps
    end
    
    add_index :saved_filters, [:user_type, :user_id, :filterable_type], 
              name: 'index_saved_filters_on_user_and_type'
    add_index :saved_filters, :conditions, using: :gin
    add_index :saved_filters, :is_default
  end
end
