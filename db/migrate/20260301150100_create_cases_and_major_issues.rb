class CreateCasesAndMajorIssues < ActiveRecord::Migration[7.2]
  def change
    create_table :cases do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name
      t.string :case_number
      t.string :case_type
      t.string :court_name
      t.string :status, default: 'pending'
      t.date :filing_at
      t.datetime :hearing_at
      t.date :judgement_received_at
      t.date :archived_at
      t.date :closing_at
      t.text :summary
      t.integer :deleted_by_employee_id
      t.datetime :deletion_requested_at
      t.integer :confirmed_by_boss_id
      t.datetime :deleted_at

      t.timestamps
    end

    create_table :major_issues do |t|
      t.references :company, null: false, foreign_key: true
      t.string :title
      t.string :issue_type
      t.string :priority, default: 'medium'
      t.string :status, default: 'pending'
      t.text :description
      t.date :resolved_at
      t.integer :mentioned_lawyer_id
      t.integer :deleted_by_employee_id
      t.datetime :deletion_requested_at
      t.integer :confirmed_by_boss_id
      t.datetime :deleted_at

      t.timestamps
    end
    
    add_index :cases, :case_number
    add_index :cases, :status
    add_index :cases, :deleted_at
    add_index :major_issues, :status
    add_index :major_issues, :priority
    add_index :major_issues, :mentioned_lawyer_id
    add_index :major_issues, :deleted_at
  end
end
