require 'rails_helper'

RSpec.describe MajorIssueTodoItem, type: :model do
  describe '待办完成后自动消除公告功能' do
    let(:company) { create(:company) }
    let(:lawyer) { create(:lawyer_account) }
    let(:major_issue) { create(:major_issue, company: company) }
    
    before do
      # 创建重大事项相关公告
      create(:announcement,
        company: company,
        announcement_type: 'custom',
        related: major_issue,
        title: "重大事项待处理：#{major_issue.title}",
        priority: 'important'
      )
    end
    
    context '当重大事项只有一个待办任务时' do
      let!(:todo) do
        major_issue.todo_items.create!(
          title: '任务1',
          status: 'pending',
          creator: lawyer
        )
      end
      
      it '完成该待办任务后自动消除相关公告' do
        expect {
          todo.complete!(lawyer)
        }.to change { 
          AnnouncementDismissal.dismissed_by_user?('major_issue_review', major_issue, lawyer) 
        }.from(false).to(true)
      end
      
      it '待办任务状态变为completed' do
        todo.complete!(lawyer)
        expect(todo.reload.status).to eq('completed')
      end
      
      it '记录完成者和完成时间' do
        todo.complete!(lawyer)
        expect(todo.reload.completed_by).to eq(lawyer)
        expect(todo.reload.completed_at).to be_present
      end
    end
    
    context '当重大事项有多个待办任务时' do
      let!(:todo1) do
        major_issue.todo_items.create!(
          title: '任务1',
          status: 'pending',
          creator: lawyer
        )
      end
      
      let!(:todo2) do
        major_issue.todo_items.create!(
          title: '任务2',
          status: 'pending',
          creator: lawyer
        )
      end
      
      let!(:todo3) do
        major_issue.todo_items.create!(
          title: '任务3',
          status: 'pending',
          creator: lawyer
        )
      end
      
      it '完成第一个待办任务后不消除公告' do
        expect {
          todo1.complete!(lawyer)
        }.not_to change { 
          AnnouncementDismissal.dismissed_by_user?('major_issue_review', major_issue, lawyer) 
        }
      end
      
      it '完成第二个待办任务后仍不消除公告' do
        todo1.complete!(lawyer)
        
        expect {
          todo2.complete!(lawyer)
        }.not_to change { 
          AnnouncementDismissal.dismissed_by_user?('major_issue_review', major_issue, lawyer) 
        }
      end
      
      it '完成最后一个待办任务后自动消除公告' do
        todo1.complete!(lawyer)
        todo2.complete!(lawyer)
        
        expect {
          todo3.complete!(lawyer)
        }.to change { 
          AnnouncementDismissal.dismissed_by_user?('major_issue_review', major_issue, lawyer) 
        }.from(false).to(true)
      end
      
      it '所有待办完成后major_issue.all_todos_completed?返回true' do
        todo1.complete!(lawyer)
        todo2.complete!(lawyer)
        todo3.complete!(lawyer)
        
        expect(major_issue.all_todos_completed?).to be true
      end
    end
    
    context '当重大事项有取消状态的待办任务时' do
      let!(:todo1) do
        major_issue.todo_items.create!(
          title: '任务1',
          status: 'pending',
          creator: lawyer
        )
      end
      
      let!(:todo2) do
        major_issue.todo_items.create!(
          title: '任务2（已取消）',
          status: 'cancelled',
          creator: lawyer
        )
      end
      
      it '不影响公告消除判断，只要active任务都完成就消除' do
        # 注意：cancelled状态的任务不会影响all_todos_completed?的判断
        # 因为只检查非completed状态的任务
        expect(major_issue.all_todos_completed?).to be false
        
        todo1.complete!(lawyer)
        
        # 由于todo2是cancelled状态，不是completed，所以all_todos_completed?返回false
        expect(major_issue.all_todos_completed?).to be false
      end
    end
    
    context '当重大事项没有待办任务时' do
      it 'all_todos_completed?返回false' do
        expect(major_issue.all_todos_completed?).to be false
      end
    end
    
    context '异常处理' do
      let!(:todo) do
        major_issue.todo_items.create!(
          title: '任务1',
          status: 'pending',
          creator: lawyer
        )
      end
      
      it '如果公告已经被消除过，不会抛出异常' do
        # 先手动消除一次
        AnnouncementDismissal.dismiss!(
          announcement_type: 'major_issue_review',
          related: major_issue,
          user: lawyer,
          reason: 'manual'
        )
        
        # 完成待办任务不应该抛出异常
        expect {
          todo.complete!(lawyer)
        }.not_to raise_error
      end
    end
  end
end
