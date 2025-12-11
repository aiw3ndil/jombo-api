require 'rails_helper'

RSpec.describe NotificationService, type: :service do
  let(:user) { create(:user) }

  describe '.create_email_notification' do
    it 'creates an email notification' do
      expect {
        NotificationService.create_email_notification(
          user,
          'welcome_email',
          'Welcome to Jombo',
          'Welcome message content'
        )
      }.to change(Notification, :count).by(1)
    end

    it 'sets correct attributes' do
      notification = NotificationService.create_email_notification(
        user,
        'booking_confirmed',
        'Your booking is confirmed',
        'Booking details',
        123
      )

      expect(notification.user).to eq(user)
      expect(notification.notification_type).to eq(Notification::TYPES[:email])
      expect(notification.email_type).to eq('booking_confirmed')
      expect(notification.title).to eq('Your booking is confirmed')
      expect(notification.content).to eq('Booking details')
      expect(notification.related_id).to eq(123)
      expect(notification.read).to be false
    end

    it 'returns nil when user is nil' do
      result = NotificationService.create_email_notification(
        nil,
        'welcome_email',
        'Title',
        'Content'
      )
      expect(result).to be_nil
    end
  end

  describe '.create_booking_notification' do
    it 'creates a booking notification' do
      expect {
        NotificationService.create_booking_notification(
          user,
          'New booking received',
          'Passenger John booked your trip',
          456
        )
      }.to change(Notification, :count).by(1)
    end

    it 'sets correct notification type' do
      notification = NotificationService.create_booking_notification(
        user,
        'Booking confirmed',
        'Your booking is confirmed',
        456
      )

      expect(notification.notification_type).to eq(Notification::TYPES[:booking])
      expect(notification.related_id).to eq(456)
    end

    it 'returns nil when user is nil' do
      result = NotificationService.create_booking_notification(nil, 'Title', 'Content', 1)
      expect(result).to be_nil
    end
  end

  describe '.create_message_notification' do
    it 'creates a message notification' do
      expect {
        NotificationService.create_message_notification(
          user,
          'New message from John',
          'Hello, how are you?',
          789
        )
      }.to change(Notification, :count).by(1)
    end

    it 'sets correct notification type' do
      notification = NotificationService.create_message_notification(
        user,
        'New message',
        'Message content',
        789
      )

      expect(notification.notification_type).to eq(Notification::TYPES[:message])
      expect(notification.related_id).to eq(789)
    end

    it 'returns nil when user is nil' do
      result = NotificationService.create_message_notification(nil, 'Title', 'Content', 1)
      expect(result).to be_nil
    end
  end

  describe '.mark_all_as_read' do
    let!(:unread1) { create(:notification, user: user, read: false) }
    let!(:unread2) { create(:notification, user: user, read: false) }
    let!(:already_read) { create(:notification, user: user, read: true) }
    let!(:other_user_notification) { create(:notification, read: false) }

    it 'marks all unread notifications as read for the user' do
      NotificationService.mark_all_as_read(user)

      expect(unread1.reload.read).to be true
      expect(unread2.reload.read).to be true
      expect(already_read.reload.read).to be true
      expect(other_user_notification.reload.read).to be false
    end

    it 'returns the number of updated notifications' do
      result = NotificationService.mark_all_as_read(user)
      expect(result).to eq(2)
    end
  end
end
