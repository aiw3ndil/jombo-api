class Notification < ApplicationRecord
  belongs_to :user

  validates :notification_type, presence: true
  validates :title, presence: true
  validates :read, inclusion: { in: [true, false] }

  scope :unread, -> { where(read: false) }
  scope :read_notifications, -> { where(read: true) }
  scope :recent, -> { order(created_at: :desc) }

  # Tipos de notificaciones
  TYPES = {
    email: 'email',
    booking: 'booking',
    message: 'message',
    review: 'review',
    trip: 'trip'
  }.freeze

  def mark_as_read!
    update(read: true)
  end

  def mark_as_unread!
    update(read: false)
  end
end
