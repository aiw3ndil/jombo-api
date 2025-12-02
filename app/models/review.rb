class Review < ApplicationRecord
  belongs_to :booking
  belongs_to :reviewer, class_name: 'User', foreign_key: 'reviewer_id'
  belongs_to :reviewee, class_name: 'User', foreign_key: 'reviewee_id'
  
  validates :rating, presence: true, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 5, only_integer: true }
  validates :booking_id, uniqueness: { scope: :reviewer_id, message: "has already been reviewed by this user" }
  validate :reviewer_participated_in_trip
  validate :cannot_review_yourself
  validate :trip_must_have_occurred
  
  private
  
  def reviewer_participated_in_trip
    return if booking.nil? || reviewer.nil?
    
    trip = booking.trip
    unless reviewer.id == trip.driver_id || reviewer.id == booking.user_id
      errors.add(:reviewer, "must be either the driver or the passenger of this booking")
    end
  end
  
  def cannot_review_yourself
    return if reviewer.nil? || reviewee.nil?
    
    if reviewer.id == reviewee.id
      errors.add(:reviewee, "cannot review yourself")
    end
  end
  
  def trip_must_have_occurred
    return if booking.nil?
    
    trip = booking.trip
    return if trip.nil?
    
    if trip.departure_time > Time.current
      errors.add(:base, "cannot review a trip that hasn't occurred yet")
    end
  end
end
