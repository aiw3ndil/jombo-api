require 'rails_helper'

RSpec.describe Notification, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:notification_type) }
    it { should validate_presence_of(:title) }
    it { should validate_inclusion_of(:read).in_array([true, false]) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let!(:read_notification) { create(:notification, user: user, read: true) }
    let!(:unread_notification1) { create(:notification, user: user, read: false) }
    let!(:unread_notification2) { create(:notification, user: user, read: false, created_at: 1.day.ago) }

    describe '.unread' do
      it 'returns only unread notifications' do
        expect(Notification.unread).to contain_exactly(unread_notification1, unread_notification2)
      end
    end

    describe '.read_notifications' do
      it 'returns only read notifications' do
        expect(Notification.read_notifications).to contain_exactly(read_notification)
      end
    end

    describe '.recent' do
      it 'returns notifications ordered by created_at desc' do
        expect(Notification.recent).to eq([unread_notification1, read_notification, unread_notification2])
      end
    end
  end

  describe '#mark_as_read!' do
    let(:notification) { create(:notification, read: false) }

    it 'marks notification as read' do
      notification.mark_as_read!
      expect(notification.reload.read).to be true
    end
  end

  describe '#mark_as_unread!' do
    let(:notification) { create(:notification, read: true) }

    it 'marks notification as unread' do
      notification.mark_as_unread!
      expect(notification.reload.read).to be false
    end
  end

  describe 'TYPES constant' do
    it 'defines notification types' do
      expect(Notification::TYPES).to eq({
        email: 'email',
        booking: 'booking',
        message: 'message',
        review: 'review',
        trip: 'trip'
      })
    end
  end
end
