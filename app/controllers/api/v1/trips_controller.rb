module Api
  module V1
    class TripsController < ApplicationController
      TRIP_INCLUDES = {
        driver: { only: [:id, :email, :name] },
        vehicle: { only: Vehicle::PUBLIC_ATTRIBUTES }
      }.freeze

      before_action :authenticate_user!, except: [:index, :show, :search]
      before_action :set_trip, only: [:show, :update, :destroy]
      before_action :authorize_driver!, only: [:update, :destroy]

      def index
        trips_query = Trip.includes(:driver, :vehicle)
                          .where('departure_time >= ?', Time.current)
                          .where(region: User::REGION)

        if params[:departure_location].present?
          trips_query = trips_query.where("departure_location ILIKE ?", "%#{params[:departure_location]}%")
        end

        if params[:arrival_location].present?
          trips_query = trips_query.where("arrival_location ILIKE ?", "%#{params[:arrival_location]}%")
        end

        @trips = trips_query

        if params[:departure_location].present? && params[:arrival_location].present?
          cache_key = "external_transport/#{params[:departure_location]}/#{params[:arrival_location]}"
          external_options = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
            ExternalTransportService.search(params[:departure_location], params[:arrival_location])
          end

          render json: {
            trips: @trips.as_json(include: TRIP_INCLUDES),
            external_options: external_options || []
          }
        else
          render json: @trips.as_json(include: TRIP_INCLUDES)
        end
      end

      def my_trips
        return render json: { error: "Unauthorized" }, status: :unauthorized unless current_user
        trips = current_user.trips.includes(:driver, :vehicle).order(created_at: :desc)
        render json: trips.as_json(include: TRIP_INCLUDES)
      end

      def search
        trips_query = Trip.includes(:driver, :vehicle)
                          .where('departure_time >= ?', Time.current)
                          .where(region: User::REGION)

        if params[:departure_location].present?
          trips_query = trips_query.where("departure_location ILIKE ?", "%#{params[:departure_location]}%")
        end

        if params[:arrival_location].present?
          trips_query = trips_query.where("arrival_location ILIKE ?", "%#{params[:arrival_location]}%")
        end

        @trips = trips_query

        if params[:departure_location].present? && params[:arrival_location].present?
          if @trips.empty?
            SearchLog.create(
              departure_location: params[:departure_location],
              arrival_location: params[:arrival_location],
              region: User::REGION,
              user_id: current_user&.id
            )
          end

          cache_key = "external_transport/#{params[:departure_location]}/#{params[:arrival_location]}"
          external_options = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
            ExternalTransportService.search(params[:departure_location], params[:arrival_location])
          end

          render json: {
            trips: @trips.as_json(include: TRIP_INCLUDES),
            external_options: external_options || []
          }
        else
          render json: @trips.as_json(include: TRIP_INCLUDES)
        end
      end

      def show
        render json: @trip.as_json(include: TRIP_INCLUDES)
      end

      def create
        return render json: { error: "Unauthorized" }, status: :unauthorized unless current_user
        trip = current_user.trips.build(trip_params.except(:vehicle_id))
        save_trip_with_vehicle(trip, status: :created)
      end

      def update
        @trip.assign_attributes(trip_params.except(:vehicle_id))
        save_trip_with_vehicle(@trip, status: :ok)
      end

      def destroy
        if params[:all_recurring] == 'true' && (@trip.is_recurring? || @trip.parent_id.present?)
          series_id = @trip.parent_id || @trip.id
          trips_to_delete = Trip.where(id: series_id).or(Trip.where(parent_id: series_id))
          
          # Solo eliminamos viajes futuros para no perder el historial de los ya realizados
          trips_to_delete = trips_to_delete.where('departure_time >= ?', Time.current)
          
          count = trips_to_delete.count
          trips_to_delete.destroy_all
          render json: { message: "#{count} trips from the series deleted successfully" }
        else
          @trip.destroy
          render json: { message: "Trip deleted successfully" }
        end
      end

      private

      def set_trip
        @trip = Trip.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Trip not found" }, status: :not_found
      end

      def trip_params
        params.require(:trip).permit(:departure_location, :arrival_location, :departure_time, 
          :available_seats, :description, :price, :vehicle_id,
          :is_recurring, :recurrence_pattern, :recurrence_days, :recurrence_until)
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
          render json: trip.as_json(include: TRIP_INCLUDES), status: status
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
