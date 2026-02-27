FactoryBot.define do
  factory :reconciliation do

    association :contract
    period { Time.current.strftime('%Y-%m') }
    uploaded_by { "Test User" }
    uploaded_at { Time.current }
    notes { "测试备注" }
    
    after(:build) do |reconciliation|
      reconciliation.attachments.attach(
        io: StringIO.new("Test file content"),
        filename: 'test_reconciliation.pdf',
        content_type: 'application/pdf'
      )
    end

  end
end
