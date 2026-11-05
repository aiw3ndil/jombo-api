# Tareas periódicas del ciclo de vida de los viajes (se ejecuta cada hora con `rails jombo:hourly`).
# Es idempotente: cada paso marca lo que ya ha procesado, así que repetirlo no envía nada dos veces.
#
# Los emails se envían con deliver_now: el proceso de la tarea termina al acabar y los jobs
# encolados en memoria se perderían.
class TripLifecycleService
  REMINDER_WINDOW = 24.hours
  PENDING_MAX_AGE = 48.hours
  PENDING_DEPARTURE_MARGIN = 2.hours
  DEFAULT_TRIP_DURATION_MINUTES = 180
  # Solo se pide valorar viajes recientes (evita emails de viajes antiguos al desplegar)
  REVIEW_LOOKBACK = 3.days

  def self.run(now: Time.current)
    new(now).run
  end

  def initialize(now)
    @now = now
  end

  def run
    {
      reminders: send_reminders,
      expired: expire_pending_requests,
      review_requests: request_reviews
    }
  end

  private

  attr_reader :now

  def upcoming_trip_ids
    Trip.where(departure_time: now..(now + REMINDER_WINDOW)).select(:id)
  end

  # Recordatorio el día antes: a cada pasajero confirmado y al conductor (un email por viaje)
  def send_reminders
    bookings = Booking.confirmed.where(reminder_sent_at: nil, trip_id: upcoming_trip_ids)
                      .includes(:user, trip: %i[driver vehicle])
    bookings.each do |booking|
      UserMailer.trip_reminder(booking).deliver_now
      booking.update_columns(reminder_sent_at: now)
    end

    trips = Trip.where(reminder_sent_at: nil, id: upcoming_trip_ids)
                .where(id: Booking.confirmed.select(:trip_id)).includes(:driver)
    trips.each do |trip|
      UserMailer.driver_trip_reminder(trip).deliver_now
      trip.update_columns(reminder_sent_at: now)
    end

    bookings.size + trips.size
  end

  # Solicitudes sin respuesta tras 48 h o a menos de 2 h de la salida
  def expire_pending_requests
    stale = Booking.pending.joins(:trip)
                   .where('bookings.created_at < :age OR trips.departure_time < :soon',
                          age: now - PENDING_MAX_AGE, soon: now + PENDING_DEPARTURE_MARGIN)
                   .includes(:user, :trip)
    stale.each do |booking|
      booking.expire!
      # Si el viaje ya salió no tiene sentido avisar
      UserMailer.booking_expired(booking).deliver_now if booking.trip.departure_time > now
    end
    stale.size
  end

  # Tras el viaje: pedir valoración al pasajero y al conductor
  def request_reviews
    ended = Booking.confirmed.joins(:trip).where(review_requested_at: nil)
                   .where("trips.departure_time + make_interval(mins => COALESCE(trips.duration_minutes, :default)) BETWEEN :from AND :to",
                          default: DEFAULT_TRIP_DURATION_MINUTES, from: now - REVIEW_LOOKBACK, to: now)
                   .includes(:user, trip: :driver)
    ended.group_by(&:trip).each do |trip, bookings|
      bookings.each { |booking| UserMailer.review_request(booking).deliver_now }
      UserMailer.driver_review_request(trip, bookings).deliver_now
      Booking.where(id: bookings.map(&:id)).update_all(review_requested_at: now)
    end
    ended.size
  end
end
