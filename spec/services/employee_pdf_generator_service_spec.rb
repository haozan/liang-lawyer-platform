require 'rails_helper'

RSpec.describe EmployeePdfGeneratorService, type: :service do
  describe '#call' do
    it 'can be initialized and called with an employee' do
      company = create(:company)
      employee = create(:employee, company: company)
      service = EmployeePdfGeneratorService.new(employee)
      expect { service.call }.not_to raise_error
    end
  end
end
