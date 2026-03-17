require 'rails_helper'

RSpec.describe MajorIssueChannel, type: :channel do
  let(:company) { Company.first || create(:company) }
  let(:major_issue) { MajorIssue.create!(
    company: company,
    title: 'Test Issue',
    description: 'Test Description',
    issue_type: 'legal_consultation',
    priority: 'high',
    status: 'pending'
  )}
  
  it 'subscribes to a valid stream' do
    subscribe(stream_name: "major_issue_#{major_issue.id}")
    expect(subscription).to be_confirmed
  end
  
  it 'rejects invalid stream name' do
    subscribe(stream_name: 'invalid_stream')
    expect(subscription).to be_rejected
  end
  
  it 'rejects non-existent major issue' do
    subscribe(stream_name: 'major_issue_99999')
    expect(subscription).to be_rejected
  end
  
  it 'broadcasts typing event' do
    subscribe(stream_name: "major_issue_#{major_issue.id}")
    
    expect {
      perform :typing, user_name: 'Test User', user_role: 'lawyer'
    }.to have_broadcasted_to("major_issue_#{major_issue.id}").with(
      type: 'user_typing',
      user_name: 'Test User',
      user_role: 'lawyer'
    )
  end
  
  it 'broadcasts stop_typing event' do
    subscribe(stream_name: "major_issue_#{major_issue.id}")
    
    expect {
      perform :stop_typing, user_name: 'Test User'
    }.to have_broadcasted_to("major_issue_#{major_issue.id}").with(
      type: 'user_stop_typing',
      user_name: 'Test User'
    )
  end
end
