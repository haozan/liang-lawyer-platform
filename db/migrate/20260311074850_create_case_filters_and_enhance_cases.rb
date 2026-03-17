class CreateCaseFiltersAndEnhanceCases < ActiveRecord::Migration[7.2]
  def change
    # 创建保存的筛选条件表
    create_table :case_filters do |t|
      t.references :user, polymorphic: true, null: false
      t.string :name, null: false
      t.jsonb :filter_params, default: {}
      t.boolean :is_default, default: false
      t.integer :position, default: 0
      t.timestamps
    end
    
    add_index :case_filters, [:user_type, :user_id, :is_default]
    add_index :case_filters, :position
    
    # 增强cases表
    add_column :cases, :priority, :string, default: 'normal'
    add_column :cases, :estimated_end_date, :date
    add_column :cases, :tags, :string, array: true, default: []
    add_column :cases, :last_activity_at, :datetime
    
    add_index :cases, :priority
    add_index :cases, :tags, using: :gin
    add_index :cases, :last_activity_at
    
    # 更新现有案件的last_activity_at
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE cases 
          SET last_activity_at = updated_at 
          WHERE last_activity_at IS NULL
        SQL
      end
    end
  end
end
