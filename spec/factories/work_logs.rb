FactoryBot.define do
  factory :work_log do

    association :case
    date { Date.today }
    title { "MyString" }
    content { "MyText" }

  end
end
