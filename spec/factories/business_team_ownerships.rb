FactoryBot.define do
  factory :business_team_ownership do

    business_type { "MyString" }
    business_id { 1 }
    lawyer_team_id { 1 }
    company_id { 1 }
    is_primary { true }
    access_level { "MyString" }
    authorized_by_id { 1 }
    authorized_at { Time.current }
    expires_at { Time.current }

  end
end
