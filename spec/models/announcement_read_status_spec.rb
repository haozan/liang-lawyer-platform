# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AnnouncementReadStatus, type: :model do
  describe 'associations' do
    it 'belongs to announcement' do
      read_status = build(:announcement_read_status)
      expect(read_status).to respond_to(:announcement)
    end

    it 'belongs to user polymorphic' do
      read_status = build(:announcement_read_status)
      expect(read_status).to respond_to(:user)
    end
  end

  describe 'validations' do
    it 'validates presence of read_at' do
      read_status = build(:announcement_read_status, read_at: nil)
      expect(read_status).not_to be_valid
      expect(read_status.errors[:read_at]).to be_present
    end
  end
end
