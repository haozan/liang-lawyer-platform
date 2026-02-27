FactoryBot.define do
  factory :company_user do

    association :company
    sequence(:email) { |n| "test_user_#{n}@test-company.com" }
    password_digest { BCrypt::Password.create('password123') }
    name { "测试用户" }
    role { "hr" }

  end
end
