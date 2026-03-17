require 'rails_helper'

RSpec.describe "Reconciliations", type: :request do
  # Authentication required - either lawyer or company user
  let(:company) { last_or_create(:company) }
  let(:contract) { create(:contract, company: company) }
  let(:company_user) { create(:company_user, company: company, role: 'employee') }
  
  before do
    # Sign in as company contract user
    session_hash = {
      current_company_user_id: company_user.id,
      user_type: 'company_user',
      viewing_company_id: company.id
    }
    allow_any_instance_of(ReconciliationsController).to receive(:session).and_return(session_hash)
  end

  describe "POST /contracts/:contract_id/reconciliations" do
    it "creates a new reconciliation with valid attributes" do
      reconciliation_params = {
        period: Time.current.strftime('%Y-%m'),
        notes: 'Test reconciliation notes',
        attachments: [
          Rack::Test::UploadedFile.new(
            StringIO.new("Test PDF content"),
            'application/pdf',
            original_filename: 'test_reconciliation.pdf'
          )
        ]
      }
      
      expect {
        post contract_reconciliations_path(contract), params: { reconciliation: reconciliation_params }
      }.to change(Reconciliation, :count).by(1)
      
      expect(response).to redirect_to(contract_path(contract))
      expect(flash[:notice]).to eq('对账单上传成功')
    end
    
    it "creates a new reconciliation with period_year and period_month (as form sends)" do
      reconciliation_params = {
        period_year: 2026,
        period_month: 3,
        notes: '2026年3月账单已完成对账，请律师审核。',
        attachments: [
          Rack::Test::UploadedFile.new(
            StringIO.new("Test PDF content"),
            'application/pdf',
            original_filename: 'test_reconciliation.pdf'
          )
        ]
      }
      
      expect {
        post contract_reconciliations_path(contract), params: { reconciliation: reconciliation_params }
      }.to change(Reconciliation, :count).by(1)
      
      expect(response).to redirect_to(contract_path(contract))
      expect(flash[:notice]).to eq('对账单上传成功')
      
      # Verify the period was correctly combined
      reconciliation = Reconciliation.last
      expect(reconciliation.period).to eq('2026-03')
    end
  end
  
  describe "DELETE /contracts/:contract_id/reconciliations/:id" do
    let!(:reconciliation) { create(:reconciliation, contract: contract) }
    
    it "deletes the reconciliation" do
      expect {
        delete contract_reconciliation_path(contract, reconciliation)
      }.to change(Reconciliation, :count).by(-1)
      
      expect(response).to redirect_to(contract_path(contract))
      expect(flash[:notice]).to eq('对账单已删除')
    end
  end
end
