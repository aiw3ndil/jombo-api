# Petición de viaje publicada por un pasajero ("busco kyyti de A a B el día X")
class RideRequest < ApplicationRecord
  STATUSES = %w[open matched closed].freeze

  belongs_to :user

  validates :departure_location, :arrival_location, :departure_date, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :flexible_days, numericality: { only_integer: true, in: 0..3 }
  validates :seats, numericality: { only_integer: true, in: 1..8 }
  validates :max_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :note, length: { maximum: 500 }
  validate :date_not_in_past, on: :create

  scope :open_upcoming, -> { where(status: 'open').where('departure_date + flexible_days >= ?', Date.current) }

  def date_range
    (departure_date - flexible_days)..(departure_date + flexible_days)
  end

  # ¿El viaje (o uno de sus tramos) sirve para esta petición?
  def matches_trip?(trip)
    segment = trip.segment_for(departure_location, arrival_location)
    return false unless segment && segment[:departure_time]
    return false unless date_range.cover?(segment[:departure_time].in_time_zone('Europe/Helsinki').to_date)
    return false if max_price.present? && segment[:price] > max_price.to_f

    trip.available_seats >= seats
  end

  private

  def date_not_in_past
    errors.add(:departure_date, 'cannot be in the past') if departure_date && departure_date < Date.current
  end
end
