module Api
  module V1
    class TripBookingsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_trip
      before_action :authorize_driver!

      def index
        bookings = @trip.bookings.includes(:user).order(created_at: :desc)
        render json: bookings.as_json(
          include: {
            user: { only: [:id, :email, :name] }
          }
        )
      end

      private

      def set_trip
        @trip = Trip.find(params[:trip_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Trip not found" }, status: :not_found
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
