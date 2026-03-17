require 'rails_helper'

RSpec.describe "CaseTeamCollaborations", type: :request do
  # Create teams first
  let!(:team1) { LawyerTeam.create!(code: 'TEST_TEAM_A', name: 'Test Team A', status: 'active', data_isolation_level: 'flexible') }
  let!(:team2) { LawyerTeam.create!(code: 'TEST_TEAM_B', name: 'Test Team B', status: 'active', data_isolation_level: 'flexible') }
  
  # Create lead lawyer and assign to team1
  let!(:lead_lawyer) do
    lawyer = LawyerAccount.find_by(phone: '18718708876') || LawyerAccount.create!(
      name: '梁家航',
      phone: '18718708876',
      password: '888888',
      password_confirmation: '888888',
      role: 'lawyer'
    )
    lawyer.update!(lawyer_team_id: team1.id)
    lawyer
  end
  let!(:company) { Company.active.first }
  let!(:case_record) { Case.where(company: company).first }
  
  before do
    # Ensure case has primary team ownership
    unless case_record.business_team_ownerships.exists?(is_primary: true)
      BusinessTeamOwnership.create!(
        business_type: 'Case',
        business_id: case_record.id,
        lawyer_team_id: team1.id,
        company_id: case_record.company_id,
        is_primary: true,
        access_level: 'owner',
        authorized_by_id: lead_lawyer.id
      )
    end
    
    # Ensure lead_lawyer is a case team member
    unless CaseTeamMember.exists?(case_id: case_record.id, lawyer_account_id: lead_lawyer.id)
      CaseTeamMember.create!(
        case_id: case_record.id,
        lawyer_account_id: lead_lawyer.id,
        role: 'lead_lawyer'
      )
    end
    
    # Login as lead lawyer
    post login_path, params: { phone: lead_lawyer.phone, password: '888888' }
  end

  describe "POST /cases/:case_id/case_team_collaborations" do
    it "adds a collaborating team" do
      # Remove team2 if it already has access
      existing = case_record.business_team_ownerships.find_by(lawyer_team: team2)
      existing&.destroy
      
      expect {
        post case_case_team_collaborations_path(case_record), params: {
          collaboration: {
            lawyer_team_id: team2.id,
            access_level: 'collaborator'
          }
        }
      }.to change { case_record.business_team_ownerships.count }.by(1)
      
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end
    
    it "prevents adding duplicate team" do
      # Add team2 first
      unless case_record.business_team_ownerships.exists?(lawyer_team: team2)
        case_record.grant_team_access!(
          team: team2,
          access_level: 'collaborator',
          authorized_by: lead_lawyer
        )
      end
      
      expect {
        post case_case_team_collaborations_path(case_record), params: {
          collaboration: {
            lawyer_team_id: team2.id,
            access_level: 'collaborator'
          }
        }
      }.not_to change { case_record.business_team_ownerships.count }
      
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /cases/:case_id/case_team_collaborations/:id" do
    let!(:collaboration) {
      # Ensure team2 has collaboration access
      case_record.business_team_ownerships.find_by(lawyer_team: team2, is_primary: false) ||
      case_record.grant_team_access!(
        team: team2,
        access_level: 'collaborator',
        authorized_by: lead_lawyer
      )
    }
    
    it "removes a collaborating team" do
      expect {
        delete case_case_team_collaboration_path(case_record, collaboration)
      }.to change { case_record.business_team_ownerships.count }.by(-1)
      
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end
    
    it "prevents removing primary team" do
      primary = case_record.business_team_ownerships.find_by(is_primary: true)
      
      expect {
        delete case_case_team_collaboration_path(case_record, primary)
      }.not_to change { case_record.business_team_ownerships.count }
      
      expect(response).to have_http_status(:found) # redirect
    end
  end
end
