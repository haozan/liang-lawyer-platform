require 'rails_helper'

RSpec.describe ReconciliationReminderJob, type: :job do
  describe '#perform' do
    it 'executes successfully' do
      expect {
        ReconciliationReminderJob.perform_now
      }.not_to raise_error
    end
  end
end
