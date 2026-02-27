require 'rails_helper'

RSpec.describe "Comments", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { last_or_create(:user) }
  # before { sign_in_as(user) }

  describe "POST /comments" do
    it "creates a new comment" do
      post comments_path, params: { comment: attributes_for(:comment) }
      expect(response).to be_success_with_view_check
    end
  end
end
