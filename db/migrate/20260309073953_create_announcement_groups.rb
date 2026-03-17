class CreateAnnouncementGroups < ActiveRecord::Migration[7.2]
  def change
    create_table :announcement_groups do |t|
      t.string :group_key, null: false
      t.string :group_name, null: false
      t.integer :priority, null: false, default: 0
      t.string :icon
      t.string :color_class

      t.timestamps
    end
    
    add_index :announcement_groups, :group_key, unique: true
    
    # 初始化分组数据
    reversible do |dir|
      dir.up do
        AnnouncementGroup.create!([
          { group_key: 'hearing_related', group_name: '开庭相关', priority: 100, icon: 'gavel', color_class: 'red' },
          { group_key: 'review_tasks', group_name: '审查待办', priority: 80, icon: 'file-check', color_class: 'orange' },
          { group_key: 'expiry_alerts', group_name: '到期提醒', priority: 70, icon: 'calendar-clock', color_class: 'yellow' },
          { group_key: 'other', group_name: '其他提醒', priority: 60, icon: 'bell', color_class: 'blue' }
        ])
      end
    end
  end
end
