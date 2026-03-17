# frozen_string_literal: true

FactoryBot.define do
  factory :announcement do
    title { "重要公告" }
    content { "这是一条测试公告内容" }
    announcement_type { 'custom' }
    priority { 'normal' }
    published_at { Time.current }
    expires_at { nil }
    association :company, factory: :company

    trait :urgent do
      priority { 'urgent' }
    end

    trait :important do
      priority { 'important' }
    end

    trait :hearing do
      announcement_type { 'hearing' }
      title { "开庭提醒" }
    end

    trait :contract_expiry do
      announcement_type { 'contract_expiry' }
      title { "合同即将到期" }
    end

    trait :contract_review do
      announcement_type { 'contract_review' }
      title { "待审查合同" }
    end

    trait :global do
      company { nil }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :unpublished do
      published_at { 1.day.from_now }
    end
  end
end
