FactoryBot.define do
  factory :notification do
    association :user
    notification_type { Notification::TYPES[:email] }
    title { "New Notification" }
    content { "This is a notification content" }
    read { false }
    email_type { "welcome_email" }
    related_id { nil }

    trait :unread do
      read { false }
    end

    trait :read do
      read { true }
    end

    trait :email_notification do
      notification_type { Notification::TYPES[:email] }
      email_type { "booking_confirmed" }
    end

    trait :booking_notification do
      notification_type { Notification::TYPES[:booking] }
      email_type { nil }
      related_id { 1 }
    end

    trait :message_notification do
      notification_type { Notification::TYPES[:message] }
      email_type { nil }
      related_id { 1 }
    end
  end
end
