class CreateCaseRelationsSeriesAndQuestions < ActiveRecord::Migration[7.2]
  def change
    # 案件关联关系表
    create_table :case_relations do |t|
      t.bigint :from_case_id, null: false
      t.bigint :to_case_id, null: false
      t.string :relation_type, null: false
      t.text :description
      t.timestamps
    end
    
    add_index :case_relations, [:from_case_id, :to_case_id], unique: true
    add_index :case_relations, :relation_type
    add_foreign_key :case_relations, :cases, column: :from_case_id
    add_foreign_key :case_relations, :cases, column: :to_case_id
    
    # 系列案件表
    create_table :case_series do |t|
      t.string :name, null: false
      t.text :description
      t.references :company, null: false, foreign_key: true
      t.references :created_by, polymorphic: true
      t.timestamps
    end
    
    # 系列案件成员关系表
    create_table :case_series_memberships do |t|
      t.references :case_series, null: false, foreign_key: true
      t.references :case, null: false, foreign_key: true
      t.integer :position, default: 0
      t.timestamps
    end
    
    add_index :case_series_memberships, [:case_series_id, :case_id], unique: true
    
    # 案件问答系统表
    create_table :case_questions do |t|
      t.references :case, null: false, foreign_key: true
      t.references :asker, polymorphic: true, null: false
      t.text :question, null: false
      t.text :answer
      t.references :answerer, polymorphic: true
      t.datetime :answered_at
      t.boolean :is_resolved, default: false
      t.timestamps
    end
    
    add_index :case_questions, :is_resolved
    add_index :case_questions, :answered_at
  end
end
