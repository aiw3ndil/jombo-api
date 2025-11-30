class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :trip

  validates :seats, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :status, presence: true, inclusion: { in: %w[pending confirmed rejected cancelled] }
  validate :not_driver

  before_create :set_default_status
  after_update :add_to_conversation, if: :saved_change_to_status?

  scope :confirmed, -> { where(status: 'confirmed') }
  scope :pending, -> { where(status: 'pending') }
  scope :rejected, -> { where(status: 'rejected') }

  def confirm_by_driver!
    return false unless status == 'pending'
    
    transaction do
      if seats > trip.available_seats
        errors.add(:seats, "not enough available seats (only #{trip.available_seats} available)")
        raise ActiveRecord::Rollback
      end
      
      trip.decrement!(:available_seats, seats)
      update!(status: 'confirmed')
    end
  end

  def reject_by_driver!
    return false unless status == 'pending'
    update!(status: 'rejected')
  end

  def cancel_by_passenger!
    return false if ['cancelled', 'rejected'].include?(status)
    
    transaction do
      if status == 'confirmed'
        trip.increment!(:available_seats, seats)
      end
      update!(status: 'cancelled')
    end
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
