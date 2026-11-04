class NotificationService
  class << self
    def create_email_notification(user, email_type, title, content = nil, related_id = nil, url: nil)
      return unless user

      Notification.create(
        user: user,
        notification_type: Notification::TYPES[:email],
        email_type: email_type,
        title: title,
        content: content,
        related_id: related_id,
        url: url,
        read: false
      )
    end

    def create_booking_notification(user, title, content = nil, booking_id = nil, url: nil)
      return unless user

      Notification.create(
        user: user,
        notification_type: Notification::TYPES[:booking],
        title: title,
        content: content,
        related_id: booking_id,
        url: url,
        read: false
      )
    end

    def create_message_notification(user, title, content = nil, message_id = nil, url: nil)
      return unless user

      Notification.create(
        user: user,
        notification_type: Notification::TYPES[:message],
        title: title,
        content: content,
        related_id: message_id,
        url: url,
        read: false
      )
    end

    def create_trip_notification(user, title, content = nil, trip_id = nil, url: nil)
      return unless user

      Notification.create(
        user: user,
        notification_type: Notification::TYPES[:trip],
        title: title,
        content: content,
        related_id: trip_id,
        url: url,
        read: false
      )
    end

    def mark_all_as_read(user)
      user.notifications.unread.update_all(read: true)
    end
  end
end
