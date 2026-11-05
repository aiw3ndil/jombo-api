class Trip < ApplicationRecord
  belongs_to :driver, class_name: 'User', foreign_key: 'driver_id'
  belongs_to :vehicle, optional: true
  has_many :bookings, dependent: :destroy
  has_many :passengers, through: :bookings, source: :user
  has_one :conversation, dependent: :destroy
  has_many :stops, -> { order(:position) }, class_name: 'TripStop', dependent: :destroy, inverse_of: :trip, autosave: true

  CHATTINESS = %w[quiet normal chatty].freeze
  LUGGAGE_SIZES = %w[small medium large].freeze
  PREFERENCE_ATTRIBUTES = %i[instant_booking pets_allowed smoking_allowed music_allowed max_two_back chattiness luggage_size].freeze
  # Compartir gastos: precio sugerido y máximo por plaza según la distancia
  SUGGESTED_PRICE_PER_KM = 0.065
  MAX_PRICE_PER_KM = 0.12
  MAX_STOPS = 5

  scope :not_cancelled, -> { where(cancelled_at: nil) }

  # Enlace a Google Maps del punto de encuentro (coordenadas si las hay, si no la dirección)
  def meeting_point_url
    return nil if meeting_point.blank?

    query = meeting_lat && meeting_lng ? "#{meeting_lat},#{meeting_lng}" : meeting_point
    "https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode(query)}"
  end

  def cancelled?
    cancelled_at.present?
  end

  # El conductor anula el viaje. Si tiene reservas activas se marca como cancelado y se
  # cancelan las reservas (para avisar a los pasajeros y contarlo en su fiabilidad);
  # si no, se borra. Devuelve las reservas canceladas (vacío si se borró).
  def cancel_by_driver!
    active = bookings.active.includes(:user).to_a
    if active.empty?
      destroy!
      return []
    end

    transaction do
      active.each { |booking| booking.cancel!(by: 'driver') }
      update_columns(cancelled_at: Time.current)
    end
    active
  end
  
  validates :departure_location, :arrival_location, :departure_time, :available_seats, :price, :region, presence: true
  validates :available_seats, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :region, inclusion: { in: %w[fi] }
  validates :vehicle, presence: true, on: :create
  validate :vehicle_belongs_to_driver
  validate :seats_fit_in_vehicle
  validates :chattiness, inclusion: { in: CHATTINESS }
  validates :luggage_size, inclusion: { in: LUGGAGE_SIZES }
  validates :distance_km, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :meeting_point, length: { maximum: 200 }
  validates :meeting_lat, numericality: { in: -90..90 }, allow_nil: true
  validates :meeting_lng, numericality: { in: -180..180 }, allow_nil: true
  before_validation :clear_meeting_coordinates, if: -> { meeting_point.blank? }
  validate :price_is_cost_sharing
  validate :stops_are_consistent
  validates :recurrence_pattern, inclusion: { in: %w[daily weekly], allow_nil: true }
  
  before_validation(on: :create) { self.region = User::REGION }

  after_create :generate_recurring_trips, if: -> { is_recurring? && parent_id.nil? }
  # Las copias de un viaje recurrente no vuelven a avisar
  after_create_commit -> { TripMatchJob.perform_later(id, ride_request_id.presence&.to_i) }, if: -> { parent_id.nil? }

  attr_accessor :ride_request_id
  
  def self.suggested_price_for(distance_km)
    return nil if distance_km.blank?

    [(distance_km.to_i * SUGGESTED_PRICE_PER_KM).round, 1].max
  end

  def self.max_price_for(distance_km)
    return nil if distance_km.blank?

    [(distance_km.to_i * MAX_PRICE_PER_KM).ceil, 2].max
  end

  def suggested_price
    self.class.suggested_price_for(distance_km)
  end

  def max_price
    self.class.max_price_for(distance_km)
  end

  def estimated_arrival_time
    departure_time + duration_minutes.minutes if departure_time && duration_minutes
  end

  # Puntos ordenados del recorrido: origen, paradas y destino, con el precio acumulado
  def points
    list = [{ location: departure_location, time: departure_time, price: BigDecimal('0') }]
    stops.each do |stop|
      list << { location: stop.location, time: stop.departure_time, price: stop.price_from_origin.to_d }
    end
    list << { location: arrival_location, time: estimated_arrival_time, price: price.to_d }
  end

  # Tramo del viaje entre dos lugares (subcadenas, sin distinguir mayúsculas).
  # Devuelve nil si el viaje no pasa por ellos en ese orden.
  def segment_for(from = nil, to = nil)
    pts = points
    last = pts.size - 1
    i = from.present? ? (0...last).find { |k| location_matches?(pts[k][:location], from) } : 0
    return nil if i.nil?

    j = to.present? ? ((i + 1)..last).find { |k| location_matches?(pts[k][:location], to) } : last
    return nil if j.nil?

    {
      from: pts[i][:location],
      to: pts[j][:location],
      departure_time: pts[i][:time],
      arrival_time: pts[j][:time],
      price: (pts[j][:price] - pts[i][:price]).round(2).to_f,
      partial: i.positive? || j < last
    }
  end

  # Sustituye todas las paradas por la lista dada (en orden)
  def assign_stops(list)
    stops.each(&:mark_for_destruction)
    Array(list).first(MAX_STOPS).each_with_index do |attrs, index|
      attrs = attrs.to_h.symbolize_keys
      next if attrs[:location].blank?

      stops.build(location: attrs[:location], departure_time: attrs[:departure_time],
                  price_from_origin: attrs[:price_from_origin] || 0, position: index + 1)
    end
  end

  # Crear conversación automáticamente si no existe
  def ensure_conversation
    conversation || create_conversation
  end

  private

  def location_matches?(location, query)
    location.to_s.downcase.include?(query.to_s.downcase.strip)
  end

  def price_is_cost_sharing
    return if price.nil? || distance_km.blank?
    return if price <= max_price

    errors.add(:price, "is too high for a cost-sharing trip (max #{max_price} € for #{distance_km} km)")
  end

  def stops_are_consistent
    kept = stops.reject(&:marked_for_destruction?)
    if kept.size > MAX_STOPS
      errors.add(:stops, "cannot be more than #{MAX_STOPS}")
      return
    end

    previous_time = departure_time
    previous_price = 0
    kept.sort_by(&:position).each do |stop|
      next if stop.departure_time.nil? || previous_time.nil?

      errors.add(:stops, 'must be in chronological order') if stop.departure_time <= previous_time
      errors.add(:stops, 'prices must increase along the route') if stop.price_from_origin.to_d < previous_price
      previous_time = stop.departure_time
      previous_price = stop.price_from_origin.to_d
    end
    errors.add(:stops, 'cannot be after the arrival') if estimated_arrival_time && previous_time && previous_time != departure_time && previous_time >= estimated_arrival_time
  end

  def vehicle_belongs_to_driver
    return if vehicle.nil? || vehicle.user_id == driver_id

    errors.add(:vehicle, 'must belong to the driver')
  end

  def seats_fit_in_vehicle
    return if vehicle.nil? || available_seats.nil?
    return unless will_save_change_to_available_seats? || will_save_change_to_vehicle_id?
    # El conductor ocupa una plaza
    return if available_seats <= vehicle.seats - 1

    errors.add(:available_seats, "cannot exceed the vehicle's passenger seats (#{vehicle.seats - 1})")
  end

  def generate_recurring_trips
    # Límite de seguridad: máximo 3 meses en el futuro o la fecha especificada
    end_date = [recurrence_until, Time.current + 3.months].compact.min
    current_time = departure_time

    while (current_time + (recurrence_pattern == 'daily' ? 1.day : 1.week)) <= end_date
      current_time += (recurrence_pattern == 'daily' ? 1.day : 1.week)
      
      # Si es semanal, verificar si el día está incluido en recurrence_days (opcional)
      if recurrence_pattern == 'weekly' && recurrence_days.present?
        days_array = recurrence_days.split(',').map(&:to_i)
        next unless days_array.include?(current_time.wday)
      end

      # Crear la instancia del viaje copia
      offset = current_time - departure_time
      copy = Trip.new(
        driver_id: driver_id,
        departure_location: departure_location,
        arrival_location: arrival_location,
        departure_time: current_time,
        available_seats: available_seats,
        price: price,
        description: description,
        region: region,
        vehicle_id: vehicle_id,
        distance_km: distance_km,
        duration_minutes: duration_minutes,
        **PREFERENCE_ATTRIBUTES.index_with { |attr| self[attr] },
        is_recurring: true,
        parent_id: id # Referencia al viaje original
      )
      stops.each do |stop|
        copy.stops.build(location: stop.location, position: stop.position,
                         departure_time: stop.departure_time + offset, price_from_origin: stop.price_from_origin)
      end
      copy.save!
    end
  end

  def clear_meeting_coordinates
    self.meeting_point = nil
    self.meeting_lat = nil
    self.meeting_lng = nil
  end
end
