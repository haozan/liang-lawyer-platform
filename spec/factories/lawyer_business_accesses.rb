FactoryBot.define do
  factory :lawyer_business_access do

    lawyer_id { 1 }
    business_type { "MyString" }
    business_id { 1 }
    access_level { "MyString" }
    reason { "MyText" }
    authorized_by_id { 1 }
    expires_at { Time.current }

  end
end
