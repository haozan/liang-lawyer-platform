FactoryBot.define do
  factory :case do
    association :company
    sequence(:name) { |n| "合同纠纷案件#{n}" }
    sequence(:case_number) { |n| "(2024)京0105民初#{10000 + n}号" }
    case_type { %w[合同纠纷 侵权纠纷 劳动争议 知识产权].sample }
    court_name { "北京市朝阳区人民法院" }
    status { "pending" }
    filing_at { 30.days.ago }
    hearing_at { 15.days.from_now }
    summary { "案件详情说明" }

    trait :in_court do
      status { "in_court" }
      hearing_at { 1.day.from_now }
    end

    trait :judgement do
      status { "judgement" }
      judgement_received_at { 2.days.ago }
    end

    trait :closed do
      status { "closed" }
      closing_at { 10.days.ago }
      archived_at { 5.days.ago }
    end

    trait :pending_deletion do
      deleted_by_employee_id { 1 }
      deletion_requested_at { 1.day.ago }
    end
  end
end
