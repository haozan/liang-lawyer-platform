FactoryBot.define do
  factory :regulation do

    association :company
    name { "规章制度" }
    
    after(:build) do |regulation|
      regulation.file.attach(
        io: StringIO.new("PDF placeholder content for regulation"),
        filename: 'test_regulation.pdf',
        content_type: 'application/pdf'
      )
    end

  end
end
