FactoryBot.define do
  factory :saved_filter do
    association :user, factory: :company_user
    user_type { 'CompanyUser' }
    name { "我的筛选条件" }
    filterable_type { 'MajorIssue' }
    conditions { { status: 'pending', priority: 'high' } }
    is_default { false }
    
    trait :with_lawyer do
      association :user, factory: :lawyer
      user_type { 'Lawyer' }
    end
    
    trait :as_default do
      is_default { true }
    end
  end
end
