FactoryBot.define do
  factory :lawyer_account do

    name { "律师" }
    email { "lawyer#{rand(10000)}@example.com" }
    password { "password123" }

  end
end
