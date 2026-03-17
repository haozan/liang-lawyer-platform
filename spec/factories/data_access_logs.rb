FactoryBot.define do
  factory :data_access_log do

    lawyer_id { 1 }
    resource_type { "MyString" }
    resource_id { 1 }
    action { "MyString" }
    access_method { "MyString" }
    ip_address { "MyString" }

  end
end
