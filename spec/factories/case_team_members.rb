FactoryBot.define do
  factory :case_team_member do
    association :case
    association :lawyer_account
    role { 'lead_lawyer' }
    joined_at { Time.current }
    
    trait :lead_lawyer do
      role { 'lead_lawyer' }
      association :lawyer_account, factory: :lawyer_account, role: 'lawyer'
    end
    
    trait :assistant_lawyer do
      role { 'assistant_lawyer' }
      association :lawyer_account, factory: :lawyer_account, role: 'lawyer'
    end
    
    trait :legal_assistant do
      role { 'legal_assistant' }
      association :lawyer_account, factory: :lawyer_account, role: 'assistant'
    end
  end
end
