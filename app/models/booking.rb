class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :trip
  has_many :reviews, dependent: :destroy

  validates :seats, presence: true, numericality: { greater_than: 0, only_integer: true }
  STATUSES = %w[pending confirmed rejected cancelled expired].freeze
  CANCELLED_BY = %w[passenger driver system].freeze

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :cancelled_by, inclusion: { in: CANCELLED_BY }, allow_nil: true
  validate :not_driver

  before_create :set_default_status
  after_update :add_to_conversation, if: :saved_change_to_status?

  scope :confirmed, -> { where(status: 'confirmed') }
  scope :pending, -> { where(status: 'pending') }
  scope :rejected, -> { where(status: 'rejected') }
  scope :active, -> { where(status: %w[pending confirmed]) }

  def confirm_by_driver!
    return false unless status == 'pending'
    
    transaction do
      if seats > trip.available_seats
        errors.add(:seats, "not enough available seats (only #{trip.available_seats} available)")
        raise ActiveRecord::Rollback
      end
      
      trip.decrement!(:available_seats, seats)
      update!(status: 'confirmed', responded_at: Time.current)
    end
  end

  def reject_by_driver!
    return false unless status == 'pending'
    update!(status: 'rejected', responded_at: Time.current)
  end

  def cancel_by_passenger!
    cancel!(by: 'passenger')
  end

  # Cancela una reserva activa (pending o confirmed) y devuelve las plazas al viaje
  def cancel!(by:)
    return false unless %w[pending confirmed].include?(status)

    transaction do
      trip.increment!(:available_seats, seats) if status == 'confirmed'
      update!(status: 'cancelled', cancelled_by: by, cancelled_at: Time.current)
    end
  end

  # Solicitud pendiente sin respuesta a tiempo
  def expire!
    return false unless status == 'pending'

    update!(status: 'expired', cancelled_by: 'system', cancelled_at: Time.current)
  end

  private

  def set_default_status
    self.status ||= 'pending'
  end

  def not_driver
    return if trip.nil? || user.nil?
    
    if user.id == trip.driver_id
      errors.add(:user, "cannot book their own trip")
    end
  end
  
  def add_to_conversation
    if status == 'confirmed'
      conversation = trip.ensure_conversation
      conversation.add_participant(user)
      conversation.add_participant(trip.driver)
    end
  end
end
