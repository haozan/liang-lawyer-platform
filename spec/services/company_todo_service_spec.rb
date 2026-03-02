require 'rails_helper'

RSpec.describe CompanyTodoService, type: :service do
  let(:company) { create(:company) }
  let(:service) { described_class.new(company: company) }

  describe '#call' do
    it 'can be initialized and called' do
      result = service.call
      
      expect(result).to be_a(Hash)
      expect(result).to have_key(:stats)
      expect(result).to have_key(:urgent_items)
      expect(result).to have_key(:pending_contracts)
      expect(result).to have_key(:pending_cases)
      expect(result).to have_key(:pending_major_issues)
    end
  end
end
