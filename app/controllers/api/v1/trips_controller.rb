module Api
  module V1
    class TripsController < ApplicationController
      before_action :authenticate_user!, except: [:index, :show, :search]
      before_action :set_trip, only: [:show, :update, :destroy]
      before_action :authorize_driver!, only: [:update, :destroy]

      def index
        trips = Trip.includes(:driver).all
        render json: trips.as_json(include: { driver: { only: [:id, :email, :name] } })
      end

      def my_trips
        trips = current_user.trips.includes(:driver).order(created_at: :desc)
        render json: trips.as_json(include: { driver: { only: [:id, :email, :name] } })
      end

      def search
        departure_location = params[:departure_location]
        trips = Trip.includes(:driver).where("departure_location ILIKE ?", "%#{departure_location}%")
        render json: trips.as_json(include: { driver: { only: [:id, :email, :name] } })
      end

      def show
        render json: @trip.as_json(include: { driver: { only: [:id, :email, :name] } })
      end

      def create
        trip = current_user.trips.build(trip_params)

        if trip.save
          render json: trip, status: :created
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
        @trip.destroy
        render json: { message: "Trip deleted successfully" }
      end

      private

      def set_trip
        @trip = Trip.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Trip not found" }, status: :not_found
      end

      def trip_params
        params.require(:trip).permit(:departure_location, :arrival_location, :departure_time, :available_seats, :price)
      end

      def authenticate_user!
        token = request.cookies["jwt"]
        payload = JwtService.decode(token)

        if payload
          @current_user = User.find_by(id: payload["user_id"] || payload[:user_id])
          render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
        else
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      def current_user
        @current_user
      end

      def authorize_driver!
        unless @trip.driver_id == current_user.id
          render json: { error: "Forbidden - You are not the driver of this trip" }, status: :forbidden
        end
      end
    end
  end
end
