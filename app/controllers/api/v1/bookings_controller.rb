module Api
  module V1
    class BookingsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_trip, only: [:index]
      before_action :set_booking, only: [:show, :update, :destroy, :confirm, :reject]
      before_action :authorize_booking_owner!, only: [:show, :update, :destroy]

      def index
        # Ensure the current user is the driver of this trip (authorization)
        unless @trip.driver == current_user
          render json: { error: "Forbidden - You are not the driver of this trip" }, status: :forbidden
          return
        end

        # Get bookings for this specific trip, including the passenger's user information
        bookings = @trip.bookings.includes(user: []).order(created_at: :desc)

        render json: bookings.as_json(
          include: {
            user: { only: [:id, :email, :name] }
          }
        )
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Trip not found" }, status: :not_found
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
        booking = trip.bookings.build(
          booking_params.merge(user: current_user, status: 'pending')
        )

        if booking.seats <= 0
          return render json: { error: 'Invalid seats' }, status: :unprocessable_entity
        end

        if booking.seats > trip.available_seats
          return render json: { error: 'Not enough seats available' }, status: :unprocessable_entity
        end

        if booking.save
          UserMailer.booking_received(trip.driver, booking).deliver_later

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
          UserMailer.booking_confirmed(@booking.user, @booking.trip).deliver_later

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
          UserMailer.booking_cancelled(@booking.user, @booking.trip).deliver_later
          render json: { message: "Booking cancelled successfully" }
        else
          render json: { error: "Cannot cancel this booking" }, status: :unprocessable_entity
        end
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def set_trip
        @trip = Trip.find(params[:trip_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Trip not found" }, status: :not_found
      end

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
