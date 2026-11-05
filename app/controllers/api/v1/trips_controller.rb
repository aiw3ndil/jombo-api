module Api
  module V1
    class TripsController < ApplicationController
      include UserPresenter

      TRIP_INCLUDES = {
        vehicle: { only: Vehicle::PUBLIC_ATTRIBUTES },
        stops: { only: [:id, :location, :position, :departure_time, :price_from_origin] }
      }.freeze
      TRIP_PERMITTED = [
        :departure_location, :arrival_location, :departure_time, :available_seats, :description, :price,
        :vehicle_id, :ride_request_id, :distance_km, :duration_minutes, :meeting_point, :meeting_lat, :meeting_lng, *Trip::PREFERENCE_ATTRIBUTES,
        :is_recurring, :recurrence_pattern, :recurrence_days, :recurrence_until
      ].freeze
      BOOLEAN_FILTERS = {
        'instant_booking' => :instant_booking, 'pets' => :pets_allowed, 'max_two_back' => :max_two_back
      }.freeze
      HELSINKI = 'Europe/Helsinki'.freeze

      before_action :authenticate_user!, except: [:index, :show, :search]
      before_action :set_trip, only: [:show, :update, :destroy]
      before_action :authorize_driver!, only: [:update, :destroy]

      def index
        render_search(log_empty: false)
      end

      def my_trips
        return render json: { error: "Unauthorized" }, status: :unauthorized unless current_user
        trips = current_user.trips.not_cancelled.includes(:driver, :vehicle, :stops).order(created_at: :desc)
        render json: trips.map { |trip| serialize_trip(trip) }
      end

      def search
        render_search(log_empty: true)
      end

      def show
        render json: serialize_trip(@trip).merge(
          suggested_price: @trip.suggested_price,
          driver: driver_profile(@trip.driver)
        )
      end

      def create
        return render json: { error: "Unauthorized" }, status: :unauthorized unless current_user
        trip = current_user.trips.build(trip_params.except(:vehicle_id))
        trip.assign_stops(stops_param) unless stops_param.nil?
        save_trip_with_vehicle(trip, status: :created)
      end

      def update
        @trip.assign_attributes(trip_params.except(:vehicle_id))
        @trip.assign_stops(stops_param) unless stops_param.nil?
        save_trip_with_vehicle(@trip, status: :ok)
      end

      def destroy
        if params[:all_recurring] == 'true' && (@trip.is_recurring? || @trip.parent_id.present?)
          series_id = @trip.parent_id || @trip.id
          trips_to_delete = Trip.where(id: series_id).or(Trip.where(parent_id: series_id))
          
          # Solo eliminamos viajes futuros para no perder el historial de los ya realizados
          trips_to_delete = trips_to_delete.where('departure_time >= ?', Time.current)
          
          trips = trips_to_delete.to_a
          cancelled = trips.count { |trip| cancel_trip(trip) }
          render json: { message: "#{trips.size} trips from the series deleted successfully", cancelled: cancelled }
        elsif @trip.departure_time < Time.current
          # Viaje ya realizado: se borra sin avisar a nadie
          @trip.destroy
          render json: { message: "Trip deleted successfully" }
        else
          cancelled = cancel_trip(@trip)
          render json: { message: cancelled ? 'Trip cancelled; passengers have been notified' : 'Trip deleted successfully',
                         cancelled: cancelled ? 1 : 0 }
        end
      end

      private

      # Cancela (o borra si no tiene reservas) y avisa a los pasajeros. true si había reservas.
      def cancel_trip(trip)
        bookings = trip.cancel_by_driver!
        bookings.each do |booking|
          UserMailer.trip_cancelled(booking).deliver_later
        end
        bookings.any?
      end

      def set_trip
        @trip = Trip.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Trip not found" }, status: :not_found
      end

      def trip_params
        params.require(:trip).permit(*TRIP_PERMITTED)
      end

      # Lista completa de paradas (nil = no tocar las existentes)
      def stops_param
        return @stops_param if defined?(@stops_param)

        raw = params[:trip]&.key?(:stops) ? params[:trip][:stops] : nil
        @stops_param = raw.nil? ? nil : Array(raw.presence).map { |stop| stop.permit(:location, :departure_time, :price_from_origin) }
      end

      def render_search(log_empty:)
        from = params[:departure_location].presence
        to = params[:arrival_location].presence
        results = filtered_results(from, to)
        payload = results.map { |trip, segment| serialize_trip(trip, segment) }

        unless from && to
          return render json: payload
        end

        if log_empty && results.empty?
          SearchLog.create(departure_location: from, arrival_location: to, region: User::REGION, user_id: (current_user || optional_user)&.id)
        end

        cache_key = "external_transport/#{from}/#{to}"
        external_options = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
          ExternalTransportService.search(from, to)
        end

        render json: { trips: payload, external_options: external_options || [] }
      end

      # Viajes futuros que pasan por "from" y luego por "to" (origen, paradas o destino),
      # con los filtros de búsqueda aplicados. Devuelve pares [trip, segmento].
      def filtered_results(from, to)
        query = Trip.not_cancelled.includes(:driver, :vehicle, :stops)
                    .where(region: User::REGION)
                    .where('trips.departure_time >= ?', Time.current - 6.hours)
        query = query.merge(location_scope('departure_location', from)) if from
        query = query.merge(location_scope('arrival_location', to)) if to

        if params[:date].present?
          day = Time.find_zone(HELSINKI).parse(params[:date].to_s) rescue nil
          # Margen de 6 h por si el pasajero sube en una parada posterior
          query = query.where(departure_time: (day.beginning_of_day - 6.hours)..day.end_of_day) if day
        end
        query = query.where('available_seats >= ?', params[:min_seats].to_i) if params[:min_seats].to_i.positive?
        BOOLEAN_FILTERS.each do |param, column|
          query = query.where(column => true) if ActiveModel::Type::Boolean.new.cast(params[param])
        end
        query = query.where(smoking_allowed: false) if ActiveModel::Type::Boolean.new.cast(params[:no_smoking])

        viewer = current_user || optional_user
        query = query.where.not(driver_id: viewer.blocked_user_ids) if viewer
        trips = query.to_a
        trips = trips.select { |trip| trip.driver&.verified_member? } if ActiveModel::Type::Boolean.new.cast(params[:verified])

        results = trips.filter_map do |trip|
          segment = trip.segment_for(from, to)
          [trip, segment] if segment && segment_matches_filters?(segment)
        end
        sort_results(results)
      end

      def location_scope(column, value)
        pattern = "%#{Trip.sanitize_sql_like(value.strip)}%"
        Trip.where(
          "trips.#{column} ILIKE :p OR EXISTS (SELECT 1 FROM trip_stops s WHERE s.trip_id = trips.id AND s.location ILIKE :p)",
          p: pattern
        )
      end

      def segment_matches_filters?(segment)
        time = segment[:departure_time]
        return false if time.nil? || time < Time.current

        local = time.in_time_zone(HELSINKI)
        if params[:date].present?
          day = Date.parse(params[:date].to_s) rescue nil
          return false if day && local.to_date != day
        end
        case params[:time_of_day]
        when 'morning' then return false unless local.hour < 12
        when 'afternoon' then return false unless (12...18).cover?(local.hour)
        when 'evening' then return false unless local.hour >= 18
        end
        return false if params[:max_price].present? && segment[:price] > params[:max_price].to_f

        true
      end

      def sort_results(results)
        case params[:sort]
        when 'price' then results.sort_by { |trip, seg| [seg[:price], seg[:departure_time]] }
        when 'duration' then results.sort_by { |trip, seg| [trip.duration_minutes || 100_000, seg[:departure_time]] }
        else results.sort_by { |_trip, seg| seg[:departure_time] }
        end
      end

      def serialize_trip(trip, segment = nil)
        json = trip.as_json(include: TRIP_INCLUDES)
        json['driver'] = driver_summary(trip.driver)
        json['segment'] = segment if segment&.dig(:partial)
        json['max_price'] = trip.max_price
        json['meeting_point_url'] = trip.meeting_point_url
        json
      end

      def driver_profile(user)
        driver_summary(user)&.merge(bio: user.bio, member_since: user.created_at)
      end

      # Guarda el viaje junto con su vehículo (existente o nuevo) en una transacción
      def save_trip_with_vehicle(trip, status:)
        vehicle = resolve_vehicle
        return if performed?

        trip.vehicle = vehicle if vehicle

        saved = Trip.transaction do
          vehicle.save! if vehicle&.new_record?
          trip.save || raise(ActiveRecord::Rollback)
        end

        if saved
          render json: serialize_trip(trip.reload), status: status
        else
          errors = trip.errors.full_messages
          errors += vehicle.errors.full_messages if vehicle&.errors&.any?
          render json: { errors: errors.uniq }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # Vehículo del viaje: uno existente del conductor (vehicle_id) o uno nuevo (vehicle: {...})
      def resolve_vehicle
        new_vehicle = params.dig(:trip, :vehicle)
        if new_vehicle.present?
          current_user.vehicles.build(
            new_vehicle.permit(*Api::V1::VehiclesController::VEHICLE_PERMITTED)
          )
        elsif trip_params[:vehicle_id].present?
          vehicle = current_user.vehicles.find_by(id: trip_params[:vehicle_id])
          render json: { errors: ["Vehicle not found"] }, status: :unprocessable_entity unless vehicle
          vehicle
        end
      end

      def current_user
        @current_user ||= find_user_from_token
      end

      def find_user_from_token
        token = request.cookies["jwt"]
        return nil if token.blank?
        
        payload = JwtService.decode(token)
        User.find_by(id: payload["user_id"] || payload[:user_id]) if payload
      rescue
        nil
      end

      def authorize_driver!
        unless @trip.driver_id == current_user&.id
          render json: { error: "Forbidden - You are not the driver of this trip" }, status: :forbidden
        end
      end

      def authenticate_user!
        render json: { error: "Unauthorized" }, status: :unauthorized unless current_user
      end
    end
  end
end
