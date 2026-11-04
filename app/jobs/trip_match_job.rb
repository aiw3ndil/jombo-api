# Avisa a los usuarios con alertas o peticiones de viaje que encajan con un viaje recién publicado
class TripMatchJob < ApplicationJob
  queue_as :default

  def perform(trip_id, offered_request_id = nil)
    trip = Trip.includes(:stops, :driver).find_by(id: trip_id)
    return unless trip && trip.departure_time > Time.current

    notified = Set.new([trip.driver_id])

    # El conductor ha publicado el viaje en respuesta a una petición concreta
    if offered_request_id && (request = RideRequest.find_by(id: offered_request_id, status: 'open'))
      unless notified.include?(request.user_id)
        UserMailer.trip_match(request.user, trip, request.departure_location, request.arrival_location, offer: true).deliver_later
        notified << request.user_id
      end
    end

    SearchAlert.active.includes(:user).find_each do |alert|
      next if notified.include?(alert.user_id) || !alert.matches_trip?(trip)

      notify(alert.user, trip, alert.departure_location, alert.arrival_location)
      alert.update_column(:last_notified_at, Time.current)
      notified << alert.user_id
    end

    RideRequest.open_upcoming.includes(:user).find_each do |request|
      next if notified.include?(request.user_id) || !request.matches_trip?(trip)

      notify(request.user, trip, request.departure_location, request.arrival_location)
      notified << request.user_id
    end
  end

  private

  def notify(user, trip, from, to)
    UserMailer.trip_match(user, trip, from, to).deliver_later
  end
end
