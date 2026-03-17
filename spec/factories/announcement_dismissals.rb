FactoryBot.define do
  factory :announcement_dismissal do
    announcement_type { "contract_review" }
    association :related, factory: :contract
    association :user, factory: :company_user
    dismissal_reason { "manual" }
    dismissed_at { Time.current }
    
    trait :auto_dismissed do
      dismissal_reason { "auto_completed" }
    end
    
    trait :for_hearing do
      announcement_type { "hearing" }
      association :related, factory: :case
    end
    
    trait :for_contract_review do
      announcement_type { "contract_review" }
      association :related, factory: :contract
    end
    
    trait :for_reconciliation do
      announcement_type { "reconciliation_overdue" }
      association :related, factory: :contract
    end
  end
end
