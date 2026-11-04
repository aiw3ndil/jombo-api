# Alerta de búsqueda: avisa al usuario cuando se publica un viaje para su ruta
class SearchAlert < ApplicationRecord
  MAX_PER_USER = 20

  belongs_to :user

  validates :departure_location, :arrival_location, presence: true
  validates :departure_location, uniqueness: { scope: [:user_id, :arrival_location, :date], case_sensitive: false,
                                               message: 'alert already exists for this route' }
  validate :limit_per_user, on: :create

  scope :active, -> { where(active: true).where('date IS NULL OR date >= ?', Date.current) }

  def matches_trip?(trip)
    segment = trip.segment_for(departure_location, arrival_location)
    return false unless segment && segment[:departure_time]
    return true if date.nil?

    segment[:departure_time].in_time_zone('Europe/Helsinki').to_date == date
  end

  private

  def limit_per_user
    return unless user && user.search_alerts.count >= MAX_PER_USER

    errors.add(:base, "You can have at most #{MAX_PER_USER} alerts")
  end
end
