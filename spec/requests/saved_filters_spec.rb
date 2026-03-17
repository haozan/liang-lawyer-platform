require 'rails_helper'

RSpec.describe "Saved filters", type: :request do

  # Uncomment this if controller need authentication
  # let(:user) { last_or_create(:user) }
  # before { sign_in_as(user) }

  describe "GET /saved_filters" do
    it "returns http success" do
      get saved_filters_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "POST /saved_filters" do
    it "creates a new saved_filter" do
      post saved_filters_path, params: { saved_filter: attributes_for(:saved_filter) }
      expect(response).to be_success_with_view_check
    end
  end


  describe "PATCH /saved_filters/:id" do
    let(:saved_filter_record) { create(:saved_filter) }

    it "updates the saved_filter" do
      patch saved_filter_path(saved_filter_record), params: { saved_filter: attributes_for(:saved_filter) }
      expect(response).to be_success_with_view_check
    end
  end
end
