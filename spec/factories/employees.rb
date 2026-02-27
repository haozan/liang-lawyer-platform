FactoryBot.define do
  factory :employee do

    association :company
    name { "张三" }
    gender { "男" }
    id_number { "440105199001011234" }
    position { "员工" }
    salary { 5000 }
    hired_at { 1.year.ago }
    probation_end_at { 9.months.ago }
    social_insurance_at { 1.year.ago }
    contract_signed_at { 1.year.ago }
    contract_end_at { 1.year.from_now }

  end
end
