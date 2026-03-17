class CreateCaseNotificationsProgressAndReports < ActiveRecord::Migration[7.2]
  def change
    # 案件通知记录表
    create_table :case_notifications do |t|
      t.references :case, null: false, foreign_key: true
      t.references :recipient, polymorphic: true, null: false
      t.string :notification_type, null: false
      t.string :title
      t.text :content
      t.jsonb :metadata, default: {}
      t.datetime :read_at
      t.datetime :sent_at
      t.boolean :email_sent, default: false
      t.boolean :sms_sent, default: false
      t.timestamps
    end
    
    add_index :case_notifications, :notification_type
    add_index :case_notifications, :read_at
    add_index :case_notifications, :sent_at
    
    # 案件进度事件表（自动生成）
    create_table :case_progress_events do |t|
      t.references :case, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :title, null: false
      t.text :description
      t.date :event_date, null: false
      t.datetime :event_time
      t.jsonb :metadata, default: {}
      t.boolean :is_milestone, default: false
      t.boolean :is_automated, default: false
      t.timestamps
    end
    
    add_index :case_progress_events, :event_type
    add_index :case_progress_events, :event_date
    add_index :case_progress_events, :is_milestone
    
    # 案件周报表（自动生成）
    create_table :case_weekly_reports do |t|
      t.references :case, null: false, foreign_key: true
      t.date :week_start_date, null: false
      t.date :week_end_date, null: false
      t.jsonb :work_summary, default: {}
      t.jsonb :next_week_plan, default: {}
      t.text :lawyer_assessment
      t.datetime :generated_at
      t.boolean :is_auto_generated, default: true
      t.timestamps
    end
    
    add_index :case_weekly_reports, :week_start_date
    add_index :case_weekly_reports, :week_end_date
    add_index :case_weekly_reports, [:case_id, :week_start_date], unique: true
  end
end
