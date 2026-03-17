FactoryBot.define do
  factory :announcement_group do
    sequence(:group_key) { |n| "custom_group_#{n}" }
    sequence(:group_name) { |n| "自定义分组 #{n}" }
    priority { 50 }
    icon { "bell" }
    color_class { "blue" }
    
    trait :hearing_related do
      group_key { "hearing_related" }
      group_name { "开庭相关" }
      priority { 100 }
      icon { "gavel" }
      color_class { "red" }
    end
    
    trait :review_tasks do
      group_key { "review_tasks" }
      group_name { "审查待办" }
      priority { 80 }
      icon { "file-check" }
      color_class { "orange" }
    end
    
    trait :expiry_alerts do
      group_key { "expiry_alerts" }
      group_name { "到期提醒" }
      priority { 70 }
      icon { "calendar-clock" }
      color_class { "yellow" }
    end
    
    trait :other do
      group_key { "other" }
      group_name { "其他提醒" }
      priority { 60 }
      icon { "bell" }
      color_class { "blue" }
    end
  end
end
