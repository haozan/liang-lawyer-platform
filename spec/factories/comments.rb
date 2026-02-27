FactoryBot.define do
  factory :comment do

    association :commentable
    author_name { "MyString" }
    author_role { "MyString" }
    content { "MyText" }

  end
end
