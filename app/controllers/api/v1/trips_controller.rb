module Api
  module V1
    class TripsController < ApplicationController
      before_action :authenticate_user!, except: [:index, :show, :search]
      before_action :set_trip, only: [:show, :update, :destroy]
      before_action :authorize_driver!, only: [:update, :destroy]

      def index
        trips_query = Trip.includes(:driver)
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
            trips: @trips.as_json(include: { driver: { only: [:id, :email, :name] } }),
            external_options: external_options || []
          }
        else
          render json: @trips.as_json(include: { driver: { only: [:id, :email, :name] } })
        end
      end

      def my_trips
        return render json: { error: "Unauthorized" }, status: :unauthorized unless current_user
        trips = current_user.trips.includes(:driver).order(created_at: :desc)
        render json: trips.as_json(include: { driver: { only: [:id, :email, :name] } })
      end

      def search
        trips_query = Trip.includes(:driver)
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
            trips: @trips.as_json(include: { driver: { only: [:id, :email, :name] } }),
            external_options: external_options || []
          }
        else
          render json: @trips.as_json(include: { driver: { only: [:id, :email, :name] } })
        end
      end

      def show
        render json: @trip.as_json(include: { driver: { only: [:id, :email, :name] } })
      end

      def create
        return render json: { error: "Unauthorized" }, status: :unauthorized unless current_user
        trip = current_user.trips.build(trip_params)

        if trip.save
          render json: trip.as_json(include: { driver: { only: [:id, :email, :name] } }), status: :created 
        else
          render json: { errors: trip.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @trip.update(trip_params)
          render json: @trip
        else
          render json: { errors: @trip.errors.full_messages }, status: :unprocessable_entity
        end
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
          :available_seats, :description, :price,
          :is_recurring, :recurrence_pattern, :recurrence_days, :recurrence_until)
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
