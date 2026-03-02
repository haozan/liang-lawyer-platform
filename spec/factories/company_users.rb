FactoryBot.define do
  factory :company_user do

    association :company
    sequence(:phone) { |n| "1380013800#{n % 10}" }
    password_digest { BCrypt::Password.create('password123') }
    name { "测试用户" }
    role { "employee" }

    trait :boss do
      role { "boss" }
      name { "老板" }
    end

    trait :employee do
      role { "employee" }
      name { "员工" }
    end

    trait :executive do
      role { "executive" }
      name { "高管" }
    end

  end
end
