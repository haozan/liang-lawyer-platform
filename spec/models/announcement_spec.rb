# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Announcement, type: :model do
  describe 'associations' do
    it 'belongs to company' do
      announcement = build(:announcement)
      expect(announcement).to respond_to(:company)
    end

    it 'belongs to related polymorphic' do
      announcement = build(:announcement)
      expect(announcement).to respond_to(:related)
    end

    it 'belongs to created_by polymorphic' do
      announcement = build(:announcement)
      expect(announcement).to respond_to(:created_by)
    end

    it 'has many read_statuses' do
      announcement = create(:announcement)
      expect(announcement).to respond_to(:read_statuses)
    end
  end

  describe 'validations' do
    it 'validates presence of title' do
      announcement = build(:announcement, title: nil)
      expect(announcement).not_to be_valid
      expect(announcement.errors[:title]).to be_present
    end

    it 'validates presence of announcement_type' do
      announcement = build(:announcement, announcement_type: nil)
      expect(announcement).not_to be_valid
      expect(announcement.errors[:announcement_type]).to be_present
    end

    it 'validates presence of priority' do
      announcement = build(:announcement, priority: nil)
      expect(announcement).not_to be_valid
      expect(announcement.errors[:priority]).to be_present
    end

    it 'validates inclusion of announcement_type' do
      valid_types = %w[hearing contract_expiry contract_review reconciliation_overdue judgement_collection custom]
      valid_types.each do |type|
        announcement = build(:announcement, announcement_type: type)
        expect(announcement).to be_valid
      end

      announcement = build(:announcement, announcement_type: 'invalid_type')
      expect(announcement).not_to be_valid
    end

    it 'validates inclusion of priority' do
      %w[urgent important normal].each do |priority|
        announcement = build(:announcement, priority: priority)
        expect(announcement).to be_valid
      end

      announcement = build(:announcement, priority: 'invalid_priority')
      expect(announcement).not_to be_valid
    end
  end

  describe 'scopes' do
    let!(:company) { create(:company) }
    let!(:published_announcement) do
      create(:announcement, company: company, published_at: 1.day.ago)
    end
    let!(:unpublished_announcement) do
      create(:announcement, company: company, published_at: 1.day.from_now)
    end
    let!(:expired_announcement) do
      create(:announcement, company: company, published_at: 2.days.ago, expires_at: 1.day.ago)
    end
    let!(:active_announcement) do
      create(:announcement, company: company, published_at: 1.day.ago, expires_at: 1.day.from_now)
    end
    let!(:global_announcement) do
      create(:announcement, company: nil, published_at: 1.day.ago)
    end

    describe '.published' do
      it 'returns only published announcements' do
        expect(Announcement.published).to include(published_announcement, expired_announcement, active_announcement, global_announcement)
        expect(Announcement.published).not_to include(unpublished_announcement)
      end
    end

    describe '.not_expired' do
      it 'returns only non-expired announcements' do
        expect(Announcement.not_expired).to include(published_announcement, unpublished_announcement, active_announcement, global_announcement)
        expect(Announcement.not_expired).not_to include(expired_announcement)
      end
    end

    describe '.active' do
      it 'returns only active announcements (published and not expired)' do
        expect(Announcement.active).to include(active_announcement, published_announcement, global_announcement)
        expect(Announcement.active).not_to include(unpublished_announcement, expired_announcement)
      end
    end

    describe '.for_company' do
      let!(:test_company_a) { create(:company, name: "测试公司A_#{SecureRandom.hex(4)}") }
      let!(:test_company_b) { create(:company, name: "测试公司B_#{SecureRandom.hex(4)}") }
      let!(:company_specific_announcement) do
        create(:announcement, company: test_company_a, published_at: 1.day.ago)
      end
      let!(:another_company_announcement) do
        create(:announcement, company: test_company_b, published_at: 1.day.ago)
      end

      it 'returns company-specific and global announcements' do
        result = Announcement.for_company(test_company_a.id)
        expect(result).to include(company_specific_announcement, global_announcement)
        expect(result).not_to include(another_company_announcement)
      end
    end
  end

  describe '#priority_color_class' do
    it 'returns red for urgent priority' do
      announcement = build(:announcement, priority: 'urgent')
      expect(announcement.priority_color_class).to eq('red')
    end

    it 'returns orange for important priority' do
      announcement = build(:announcement, priority: 'important')
      expect(announcement.priority_color_class).to eq('orange')
    end

    it 'returns blue for normal priority' do
      announcement = build(:announcement, priority: 'normal')
      expect(announcement.priority_color_class).to eq('blue')
    end
  end

  describe '#read_by?' do
    let(:company) { create(:company) }
    let(:company_user) { create(:company_user, company: company) }
    let(:announcement) { create(:announcement, company: company) }

    it 'returns false if user has not read the announcement' do
      expect(announcement.read_by?(company_user)).to be false
    end

    it 'returns true if user has read the announcement' do
      create(:announcement_read_status, announcement: announcement, user: company_user)
      expect(announcement.read_by?(company_user)).to be true
    end

    it 'returns false if user is nil' do
      expect(announcement.read_by?(nil)).to be false
    end
  end

  describe '#mark_as_read_by' do
    let(:company) { create(:company) }
    let(:company_user) { create(:company_user, company: company) }
    let(:announcement) { create(:announcement, company: company) }

    it 'creates a read status record' do
      expect do
        announcement.mark_as_read_by(company_user)
      end.to change(AnnouncementReadStatus, :count).by(1)
    end

    it 'does not create duplicate read status records' do
      announcement.mark_as_read_by(company_user)
      expect do
        announcement.mark_as_read_by(company_user)
      end.not_to change(AnnouncementReadStatus, :count)
    end

    it 'returns false if user is nil' do
      expect(announcement.mark_as_read_by(nil)).to be false
    end
  end
end
