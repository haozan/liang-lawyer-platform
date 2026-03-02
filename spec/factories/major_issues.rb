FactoryBot.define do
  factory :major_issue do
    association :company
    sequence(:title) { |n| "重大事项讨论#{n}" }
    description { "需要律师提供专业意见的重大事项" }
    issue_type { %w[法律风险 财务问题 战略决策 人事变动 合规审查 商业谈判 其他].sample }
    priority { %w[low medium high urgent].sample }
    status { "pending" }

    trait :with_lawyer do
      association :mentioned_lawyer, factory: :lawyer_account
    end

    trait :discussing do
      status { "discussing" }
    end

    trait :resolved do
      status { "resolved" }
      resolved_at { 3.days.ago }
    end

    trait :high_priority do
      priority { "high" }
    end

    trait :urgent do
      priority { "urgent" }
    end

    trait :pending_deletion do
      deleted_by_employee_id { 1 }
      deletion_requested_at { 1.day.ago }
    end
  end
end
