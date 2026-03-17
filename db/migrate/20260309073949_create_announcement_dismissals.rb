class CreateAnnouncementDismissals < ActiveRecord::Migration[7.2]
  def change
    create_table :announcement_dismissals do |t|
      t.string :announcement_type, null: false
      t.references :related, polymorphic: true, null: false
      t.references :user, polymorphic: true, null: false
      t.string :dismissal_reason
      t.datetime :dismissed_at, null: false

      t.timestamps
    end
    
    add_index :announcement_dismissals, [:announcement_type, :related_type, :related_id], name: 'idx_dismissal_lookup'
    add_index :announcement_dismissals, [:user_type, :user_id]
  end
end
