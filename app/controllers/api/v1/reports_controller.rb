module Api
  module V1
    # Reportar a un usuario (el administrador recibe un email)
    class ReportsController < ApplicationController
      before_action :authenticate_user!

      # POST /api/v1/reports { reported_id, reason, comment, booking_id }
      def create
        report = current_user.reports_made.build(params.permit(:reported_id, :reason, :comment, :booking_id))
        if report.booking_id && !shared_booking?(report)
          return render json: { error: 'Booking not found' }, status: :unprocessable_entity
        end

        if report.save
          AdminMailer.new_report(report).deliver_later
          render json: { message: 'Report sent' }, status: :created
        else
          render json: { errors: report.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      # La reserva debe ser un viaje compartido entre quien reporta y el reportado
      def shared_booking?(report)
        booking = Booking.includes(:trip).find_by(id: report.booking_id)
        return false unless booking

        people = [booking.user_id, booking.trip.driver_id]
        people.include?(report.reporter_id) && people.include?(report.reported_id)
      end
    end
  end
end
