# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeamAccessible, type: :concern do
  let(:company) { Company.active.first || FactoryBot.create(:company, status: 'active') }
  let!(:default_team) do
    LawyerTeam.find_or_create_by!(code: 'DEFAULT_TEAM') do |team|
      team.name = '默认律师团队'
      team.status = 'active'
      team.data_isolation_level = 'flexible'
    end
  end
  let!(:custom_team) do
    LawyerTeam.where.not(code: 'DEFAULT_TEAM').active.first || LawyerTeam.create!(
      code: 'TEST_TEAM_A',
      name: 'Test Custom Team',
      status: 'active',
      data_isolation_level: 'flexible'
    )
  end
  let!(:lawyer) do
    # Get existing lawyer or create one
    existing_lawyer = LawyerAccount.find_by(phone: '18718708876')
    if existing_lawyer
      # Update lawyer to be in custom_team
      existing_lawyer.update!(lawyer_team_id: custom_team.id)
      existing_lawyer
    else
      LawyerAccount.create!(
        name: 'Test Lawyer',
        phone: '13900000001',
        password: '888888',
        password_confirmation: '888888',
        lawyer_team_id: custom_team.id
      )
    end
  end
  
  before do
    # Ensure default team has a leader
    if default_team.leader_id.nil?
      default_team.update!(leader_id: lawyer.id)
    end
  end

  describe 'Contract#create_team_ownership' do
    context 'when created by lawyer' do
      it 'associates contract with lawyer team' do
        # Set Current.lawyer_account to simulate lawyer session
        Current.lawyer_account = lawyer
        
        contract = company.contracts.create!(
          name: 'Test Contract by Lawyer',
          signed_at: Date.today,
          end_at: Date.today + 1.year,
          status: 'active',
          counterparty_name: 'Test Party',
          counterparty_role: '甲方',
          our_party_role: '乙方',
          contract_type: '服务合同',
          file: { io: File.open(Rails.root.join('README.md')), filename: 'test.pdf' }
        )
        
        ownership = contract.business_team_ownerships.first
        
        expect(ownership).to be_present
        expect(ownership.lawyer_team_id).to eq(custom_team.id)
        expect(ownership.is_primary).to be true
        expect(ownership.access_level).to eq('owner')
        expect(ownership.authorized_by_id).to eq(lawyer.id)
        
        # Cleanup
        contract.destroy
        Current.lawyer_account = nil
      end
    end
    
    context 'when created by company user (no lawyer session)' do
      it 'associates contract with DEFAULT_TEAM' do
        # Set Current.lawyer_account to nil to simulate company user session
        Current.lawyer_account = nil
        
        contract = company.contracts.create!(
          name: 'Test Contract by Company User',
          signed_at: Date.today,
          end_at: Date.today + 1.year,
          status: 'active',
          counterparty_name: 'Test Party',
          counterparty_role: '甲方',
          our_party_role: '乙方',
          contract_type: '服务合同',
          file: { io: File.open(Rails.root.join('README.md')), filename: 'test.pdf' }
        )
        
        ownership = contract.business_team_ownerships.first
        
        expect(ownership).to be_present
        expect(ownership.lawyer_team.code).to eq('DEFAULT_TEAM')
        expect(ownership.is_primary).to be true
        expect(ownership.access_level).to eq('owner')
        expect(ownership.authorized_by_id).to eq(default_team.leader_id)
        
        # Verify DEFAULT_TEAM lawyers can access
        default_team.reload
        expect(contract.accessible_by?(lawyer)).to be true
        expect(Contract.accessible_by(lawyer).where(id: contract.id).exists?).to be true
        
        # Cleanup
        contract.destroy
      end
    end
  end
  
  describe 'MajorIssue#create_team_ownership' do
    context 'when created by lawyer' do
      it 'associates major issue with lawyer team' do
        Current.lawyer_account = lawyer
        
        major_issue = company.major_issues.create!(
          title: 'Test Issue by Lawyer',
          description: 'Test description',
          issue_type: '法律咨询',
          priority: 'high',
          status: 'pending'
        )
        
        ownership = major_issue.business_team_ownerships.first
        
        expect(ownership).to be_present
        expect(ownership.lawyer_team_id).to eq(custom_team.id)
        expect(ownership.is_primary).to be true
        
        major_issue.destroy
        Current.lawyer_account = nil
      end
    end
    
    context 'when created by company user' do
      it 'associates major issue with DEFAULT_TEAM' do
        Current.lawyer_account = nil
        
        major_issue = company.major_issues.create!(
          title: 'Test Issue by Company User',
          description: 'Test description',
          issue_type: '法律咨询',
          priority: 'high',
          status: 'pending'
        )
        
        ownership = major_issue.business_team_ownerships.first
        
        expect(ownership).to be_present
        expect(ownership.lawyer_team.code).to eq('DEFAULT_TEAM')
        expect(ownership.is_primary).to be true
        
        # Verify access
        expect(major_issue.accessible_by?(lawyer)).to be true
        
        major_issue.destroy
      end
    end
  end
  
  describe 'Case#create_team_ownership' do
    context 'when created by lawyer' do
      it 'associates case with lawyer team' do
        Current.lawyer_account = lawyer
        
        legal_case = company.cases.create!(
          name: 'Test Case by Lawyer',
          case_type: '民事',
          status: 'filed',
          filing_at: Date.today,
          case_number: 'TEST-2024-001'  # 添加必填字段
        )
        
        ownership = legal_case.business_team_ownerships.first
        
        expect(ownership).to be_present
        expect(ownership.lawyer_team_id).to eq(custom_team.id)
        expect(ownership.is_primary).to be true
        
        legal_case.destroy
        Current.lawyer_account = nil
      end
    end
    
    context 'when created by company user' do
      it 'associates case with DEFAULT_TEAM' do
        Current.lawyer_account = nil
        
        legal_case = company.cases.create!(
          name: 'Test Case by Company User',
          case_type: '民事',
          status: 'filed',
          filing_at: Date.today,
          case_number: 'TEST-2024-002'
        )
        
        ownership = legal_case.business_team_ownerships.first
        
        expect(ownership).to be_present
        expect(ownership.lawyer_team.code).to eq('DEFAULT_TEAM')
        expect(ownership.is_primary).to be true
        
        legal_case.destroy
      end
    end
  end
end
