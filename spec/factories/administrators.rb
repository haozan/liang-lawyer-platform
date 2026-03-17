FactoryBot.define do
  factory :administrator do
    sequence(:name) { |n| "admin#{n}" }
    sequence(:phone) { |n| "1%010d" % (n + 3000000000) }  # 生成类似 13000000001, 13000000002 的手机号
    password { "admin" }
    role { "admin" }
    
    trait :super_admin do
      role { "super_admin" }
    end
  end
end
