require 'rails_helper'

RSpec.describe "Comments", type: :request do

  let(:lawyer) { last_or_create(:lawyer_account) }
  let(:contract) { last_or_create(:contract) }
  
  def sign_in_lawyer(lawyer_account)
    post login_path, params: { 
      phone: lawyer_account.phone, 
      password: 'password123',
      user_type: 'lawyer'
    }
  end
  
  before { sign_in_lawyer(lawyer) }

  describe "POST /comments" do
    it "creates a new comment" do
      post contract_comments_path(contract), params: { 
        comment: { 
          content: "这是一条测试评论" 
        } 
      }
      expect(response).to be_success_with_view_check
    end
  end
end
