# Parada intermedia de un viaje. Los pasajeros pueden subir o bajar en ella;
# price_from_origin es el precio por plaza desde el origen hasta esta parada.
class TripStop < ApplicationRecord
  belongs_to :trip, inverse_of: :stops

  validates :location, :position, :departure_time, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 }
  validates :price_from_origin, numericality: { greater_than_or_equal_to: 0 }
  validate :price_within_trip
  validate :time_after_departure

  private

  def price_within_trip
    return if trip.nil? || trip.price.nil? || price_from_origin.nil?
    return if price_from_origin <= trip.price

    errors.add(:price_from_origin, 'cannot exceed the full trip price')
  end

  def time_after_departure
    return if trip.nil? || trip.departure_time.nil? || departure_time.nil?
    return if departure_time > trip.departure_time

    errors.add(:departure_time, 'must be after the trip departure')
  end
end
