FactoryBot.define do
  factory :case do
    association :company
    sequence(:name) { |n| "合同纠纷案件#{n}" }
    sequence(:case_number) { |n| "(2024)京0105民初#{10000 + n}号" }
    case_type { %w[合同纠纷 侵权纠纷 劳动争议 知识产权].sample }
    court_name { "北京市朝阳区人民法院" }
    status { "preparing" }
    filing_at { 30.days.ago }
    hearing_at { 15.days.from_now }
    summary { "案件详情说明" }
    
    # 标的额相关
    claim_amount { 1_000_000.00 }
    litigation_fee { 10_000.00 }
    lawyer_fee { 50_000.00 }
    amount_status { 'pending' }
    
    # 当事人信息
    our_party_name { company&.name || "某某公司" }
    our_party_role { '原告' }
    counterparty_name { "某某公司" }
    counterparty_role { '被告' }

    trait :in_court do
      status { "trial" }
      stage { "first_trial" }
      hearing_at { 1.day.from_now }
    end

    trait :judgement do
      status { "judged" }
      stage { "first_trial" }
      judgement_received_at { 2.days.ago }
      awarded_amount { 800_000.00 }
      amount_status { 'awarded' }
      case_outcome { 'partial_win' }
    end
    
    trait :high_value do
      claim_amount { 5_000_000.00 }
      priority { 'urgent' }
    end
    
    trait :with_execution do
      status { "execution" }
      stage { "execution" }
      awarded_amount { 1_000_000.00 }
      executed_amount { 300_000.00 }
      execution_start_at { 1.month.ago }
      execution_status { 'executing' }
    end

    trait :closed do
      status { "closed" }
      closing_at { 10.days.ago }
      archived_at { 5.days.ago }
      awarded_amount { claim_amount }
      executed_amount { awarded_amount }
      amount_status { 'paid' }
      case_outcome { 'total_win' }
      execution_status { 'completed' }
    end

    trait :pending_deletion do
      deleted_by_employee_id { 1 }
      deletion_requested_at { 1.day.ago }
    end
  end
end
