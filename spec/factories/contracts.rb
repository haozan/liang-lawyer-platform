FactoryBot.define do
  factory :contract do

    association :company
    name { "测试合同" }
    signed_at { 6.months.ago }
    end_at { 6.months.from_now }
    status { "active" }
    
    after(:build) do |contract|
      contract.file.attach(
        io: StringIO.new("PDF placeholder content"),
        filename: 'test_contract.pdf',
        content_type: 'application/pdf'
      )
    end

  end
end
