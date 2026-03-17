require 'rails_helper'

RSpec.describe UnifiedTodoService, type: :service do
  let(:company) { Company.create!(name: 'Test Company', service_expires_at: 1.year.from_now) }
  
  describe '#call' do
    context 'for lawyer' do
      it 'can be initialized and called without company_id' do
        service = UnifiedTodoService.new(user_type: :lawyer)
        expect { service.call }.not_to raise_error
      end
      
      it 'can be initialized and called with company_id' do
        service = UnifiedTodoService.new(company_id: company.id, user_type: :lawyer)
        expect { service.call }.not_to raise_error
      end
      
      it 'returns expected data structure' do
        service = UnifiedTodoService.new(user_type: :lawyer)
        result = service.call
        
        expect(result).to have_key(:stats)
        expect(result).to have_key(:urgent_items)
        expect(result).to have_key(:pending_contracts)
        expect(result).to have_key(:pending_cases)
        expect(result).to have_key(:pending_major_issues)
        expect(result).to have_key(:company_todos)
      end
    end
    
    context 'for company user' do
      it 'can be initialized and called with company' do
        service = UnifiedTodoService.new(company: company, user_type: :company)
        expect { service.call }.not_to raise_error
      end
      
      it 'returns expected data structure' do
        service = UnifiedTodoService.new(company: company, user_type: :company)
        result = service.call
        
        expect(result).to have_key(:stats)
        expect(result).to have_key(:urgent_items)
        expect(result).to have_key(:pending_contracts)
        expect(result).to have_key(:pending_cases)
        expect(result).to have_key(:pending_major_issues)
        expect(result).not_to have_key(:company_todos)
      end
    end
  end
  
  describe '#calculate_stats' do
    it 'returns stats with expected keys' do
      service = UnifiedTodoService.new(company: company, user_type: :company)
      result = service.call
      stats = result[:stats]
      
      expect(stats).to have_key(:today_new)
      expect(stats).to have_key(:total_pending)
      expect(stats).to have_key(:this_week_reviewed)
      expect(stats).to have_key(:urgent)
    end
  end
end
