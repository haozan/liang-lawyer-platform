require 'rails_helper'

RSpec.describe Comment, type: :model do
  describe '合同审查后自动消除公告功能' do
    let(:lawyer_team) { create(:lawyer_team) }
    let(:lawyer) { create(:lawyer_account, lawyer_team: lawyer_team) }
    let(:company) { create(:company, lawyer_team: lawyer_team) }
    let(:contract) { create(:contract, company: company, reviewed_by_lawyer: false) }
    
    context '当律师添加评论时' do
      it '自动消除合同审查公告（使用 author 关联）' do
        # 创建评论，设置 author 关联
        comment = contract.comments.create!(
          content: '合同已审查，无风险',
          author: lawyer,
          author_name: lawyer.display_name,
          author_role: 'lawyer'
        )
        
        # 验证公告已被消除
        expect(
          AnnouncementDismissal.dismissed_by_user?('contract_review', contract, lawyer)
        ).to be true
        
        # 验证消除原因
        dismissal = AnnouncementDismissal.where(
          announcement_type: 'contract_review',
          related: contract,
          user: lawyer
        ).first
        expect(dismissal.dismissal_reason).to eq('reviewed')
      end
      
      it '自动消除合同审查公告（使用 author_name 推断）' do
        # 创建评论，不设置 author 关联，只设置 author_name
        comment = contract.comments.create!(
          content: '合同已审查，无风险',
          author_name: "#{lawyer.name}（律师）",
          author_role: 'lawyer'
        )
        
        # 验证公告已被消除
        expect(
          AnnouncementDismissal.dismissed_by_user?('contract_review', contract, lawyer)
        ).to be true
      end
      
      it '如果公告已被消除，不会抛出异常' do
        # 先手动消除公告
        AnnouncementDismissal.dismiss!(
          announcement_type: 'contract_review',
          related: contract,
          user: lawyer,
          reason: 'manual'
        )
        
        # 创建评论，不应该抛出异常
        expect {
          contract.comments.create!(
            content: '再次审查',
            author: lawyer,
            author_name: lawyer.display_name,
            author_role: 'lawyer'
          )
        }.not_to raise_error
      end
    end
    
    context '当助理添加评论时' do
      it '不会自动消除公告' do
        assistant = create(:lawyer_account, role: 'assistant', lawyer_team: lawyer_team)
        
        comment = contract.comments.create!(
          content: '助理意见',
          author: assistant,
          author_name: assistant.display_name,
          author_role: 'assistant'
        )
        
        # 验证公告没有被消除
        expect(
          AnnouncementDismissal.dismissed_by_user?('contract_review', contract, lawyer)
        ).to be false
      end
    end
    
    context '当团队负责人添加评论时' do
      it '自动消除合同审查公告' do
        team_leader = create(:lawyer_account, role: 'team_leader', lawyer_team: lawyer_team)
        
        comment = contract.comments.create!(
          content: '审查完成',
          author: team_leader,
          author_name: team_leader.display_name,
          author_role: 'team_leader'
        )
        
        # 验证公告已被消除
        expect(
          AnnouncementDismissal.dismissed_by_user?('contract_review', contract, team_leader)
        ).to be true
      end
    end
    
    context '当资深律师添加评论时' do
      it '自动消除合同审查公告' do
        senior_lawyer = create(:lawyer_account, role: 'senior_lawyer', lawyer_team: lawyer_team)
        
        comment = contract.comments.create!(
          content: '审查完成',
          author: senior_lawyer,
          author_name: senior_lawyer.display_name,
          author_role: 'senior_lawyer'
        )
        
        # 验证公告已被消除
        expect(
          AnnouncementDismissal.dismissed_by_user?('contract_review', contract, senior_lawyer)
        ).to be true
      end
    end
    
    context '对账单审查' do
      let(:reconciliation) { create(:reconciliation, contract: contract, reviewed_by_lawyer: false) }
      
      it '律师评论后自动消除对账单审查公告' do
        comment = reconciliation.comments.create!(
          content: '对账单已审查',
          author: lawyer,
          author_name: lawyer.display_name,
          author_role: 'lawyer'
        )
        
        # 验证公告已被消除
        expect(
          AnnouncementDismissal.dismissed_by_user?('reconciliation_review', reconciliation, lawyer)
        ).to be true
      end
    end
    
    context '重大事项审查' do
      let(:major_issue) { create(:major_issue, company: company, reviewed_by_lawyer: false) }
      
      it '律师评论后自动消除重大事项审查公告' do
        comment = major_issue.comments.create!(
          content: '重大事项已审查',
          author: lawyer,
          author_name: lawyer.display_name,
          author_role: 'lawyer'
        )
        
        # 验证公告已被消除
        expect(
          AnnouncementDismissal.dismissed_by_user?('major_issue_review', major_issue, lawyer)
        ).to be true
      end
    end
    
    context '边界情况' do
      it '如果无法推断律师账户，不会抛出异常' do
        expect {
          contract.comments.create!(
            content: '匿名评论',
            author_name: '未知律师',
            author_role: 'lawyer'
          )
        }.not_to raise_error
        
        # 验证公告没有被消除
        expect(
          AnnouncementDismissal.dismissed_by_user?('contract_review', contract, lawyer)
        ).to be false
      end
      
      it '公司用户评论不会触发公告消除' do
        company_user = create(:company_user, company: company)
        
        comment = contract.comments.create!(
          content: '公司用户意见',
          author: company_user,
          author_name: company_user.display_name,
          author_role: 'boss'
        )
        
        # 验证公告没有被消除
        expect(
          AnnouncementDismissal.dismissed_by_user?('contract_review', contract, lawyer)
        ).to be false
      end
    end
  end
end
