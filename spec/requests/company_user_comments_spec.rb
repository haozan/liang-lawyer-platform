require 'rails_helper'

RSpec.describe "Company User Comments on Major Issues", type: :request do
  let(:company) { create(:company) }
  let(:company_user) { create(:company_user, company: company, role: 'boss') }
  let(:major_issue) { create(:major_issue, company: company) }
  
  before do
    # 模拟企业用户登录
    allow_any_instance_of(ApplicationController).to receive(:current_company_user).and_return(company_user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(company_user)
    allow_any_instance_of(ApplicationController).to receive(:current_lawyer).and_return(nil)
    allow_any_instance_of(ApplicationController).to receive(:company_user?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:lawyer?).and_return(false)
  end
  
  describe "GET /major_issues/:id (show page)" do
    it "displays comment form for company users" do
      get major_issue_path(major_issue)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('发表意见')
      expect(response.body).to include('提交意见')
    end
  end
  
  describe "POST /major_issues/:id/comments (create comment)" do
    it "allows company user to create a comment" do
      expect {
        post major_issue_comments_path(major_issue), params: {
          comment: {
            content: "这是企业用户的意见"
          }
        }
      }.to change(Comment, :count).by(1)
      
      created_comment = Comment.last
      expect(created_comment.author).to eq(company_user)
      expect(created_comment.author_name).to eq(company_user.display_name)
      expect(created_comment.author_role).to eq('boss')
      expect(created_comment.review_status).to eq('approved') # 企业用户评论自动审核通过
      expect(created_comment.commentable).to eq(major_issue)
    end
    
    it "displays company user role badge correctly" do
      post major_issue_comments_path(major_issue), params: {
        comment: { content: "测试评论" }
      }
      
      get major_issue_path(major_issue)
      expect(response.body).to include('老板') # 角色徽章应该显示"老板"
    end
  end
end
