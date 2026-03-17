# frozen_string_literal: true

FactoryBot.define do
  factory :announcement_read_status do
    association :announcement
    association :user, factory: :company_user
    read_at { Time.current }
  end
end
