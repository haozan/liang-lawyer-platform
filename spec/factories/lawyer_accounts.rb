FactoryBot.define do
  factory :lawyer_account do
    name { "律师" }
    phone { "138#{rand(10000000).to_s.rjust(8, '0')}" }
    password { "password123" }
    role { "lawyer" }
  end
end
