FactoryBot.define do
  factory :lawyer_team do
    sequence(:name) { |n| "测试律师团队#{n}" }
    sequence(:code) { |n| "TEAM_#{('A'.ord + n).chr}" }
    leader_id { nil }
    data_isolation_level { 'flexible' }
    status { 'active' }
  end
end
