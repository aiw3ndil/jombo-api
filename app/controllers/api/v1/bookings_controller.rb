module Api
  module V1
    class BookingsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_booking, only: [:show, :update, :destroy, :confirm, :reject]
      before_action :authorize_booking_owner!, only: [:show, :update, :destroy]

      def index
        bookings = current_user.bookings.includes(trip: :driver).order(created_at: :desc)
        render json: bookings.as_json(
          include: {
            trip: {
              include: { driver: { only: [:id, :email, :name] } }
            }
          }
        )
      end

      def show
        render json: @booking.as_json(
          include: {
            trip: {
              include: { driver: { only: [:id, :email, :name] } }
            }
          }
        )
      end

      def create
        trip = Trip.find(params[:trip_id])
        
        booking = current_user.bookings.build(
          trip: trip,
          seats: booking_params[:seats] || 1,
          status: 'pending'
        )

        if booking.save
          render json: booking.as_json(
            include: {
              trip: {
                include: { driver: { only: [:id, :email, :name] } }
              }
            }
          ), status: :created
        else
          render json: { errors: booking.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Trip not found" }, status: :not_found
      end

      def update
        if @booking.status == 'cancelled'
          render json: { error: "Cannot update a cancelled booking" }, status: :unprocessable_entity
          return
        end

        if @booking.update(status: params[:status])
          render json: @booking
        else
          render json: { errors: @booking.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def confirm
        unless @booking.trip.driver_id == current_user.id
          render json: { error: "Forbidden - Only the driver can confirm bookings" }, status: :forbidden
          return
        end

        if @booking.confirm_by_driver!
          render json: @booking.as_json(
            include: {
              trip: {
                include: { driver: { only: [:id, :email, :name] } }
              },
              user: { only: [:id, :email, :name] }
            }
          )
        else
          render json: { errors: @booking.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def reject
        unless @booking.trip.driver_id == current_user.id
          render json: { error: "Forbidden - Only the driver can reject bookings" }, status: :forbidden
          return
        end

        if @booking.reject_by_driver!
          render json: @booking
        else
          render json: { error: "Cannot reject this booking" }, status: :unprocessable_entity
        end
      end

      def destroy
        if @booking.status == 'cancelled'
          render json: { error: "Booking already cancelled" }, status: :unprocessable_entity
          return
        end

        if @booking.cancel_by_passenger!
          render json: { message: "Booking cancelled successfully" }
        else
          render json: { error: "Cannot cancel this booking" }, status: :unprocessable_entity
        end
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def set_booking
        @booking = Booking.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Booking not found" }, status: :not_found
      end

      def booking_params
        params.require(:booking).permit(:seats, :status)
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

      def authorize_booking_owner!
        unless @booking.user_id == current_user.id
          render json: { error: "Forbidden - You are not the owner of this booking" }, status: :forbidden
        end
      end
    end
  end
end
