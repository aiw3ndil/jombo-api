module Api
  module V1
    # Peticiones de viaje de pasajeros (tablón público)
    class RideRequestsController < ApplicationController
      PERMITTED = [:departure_location, :arrival_location, :departure_date, :flexible_days, :seats, :max_price, :note].freeze

      before_action :authenticate_user!, except: [:index, :show]
      before_action :set_own_request, only: [:update, :destroy]

      def index
        requests = RideRequest.open_upcoming.includes(:user).order(:departure_date, :created_at)
        requests = requests.where('departure_location ILIKE ?', like(params[:from])) if params[:from].present?
        requests = requests.where('arrival_location ILIKE ?', like(params[:to])) if params[:to].present?
        if params[:date].present? && (date = Date.parse(params[:date]) rescue nil)
          requests = requests.where('departure_date - flexible_days <= :d AND departure_date + flexible_days >= :d', d: date)
        end
        render json: requests.limit(100).map { |r| serialize(r) }
      end

      def show
        request = RideRequest.includes(:user).find_by(id: params[:id])
        return render json: { error: 'Ride request not found' }, status: :not_found unless request

        render json: serialize(request)
      end

      def mine
        render json: current_user.ride_requests.order(departure_date: :desc).map { |r| serialize(r) }
      end

      def create
        request = current_user.ride_requests.build(params.require(:ride_request).permit(*PERMITTED))
        if request.save
          render json: serialize(request), status: :created
        else
          render json: { errors: request.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        attrs = params.require(:ride_request).permit(*PERMITTED, :status)
        if @request.update(attrs)
          render json: serialize(@request)
        else
          render json: { errors: @request.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @request.destroy
        head :no_content
      end

      private

      def like(value)
        "%#{RideRequest.sanitize_sql_like(value.to_s.strip)}%"
      end

      def set_own_request
        @request = current_user.ride_requests.find_by(id: params[:id])
        render json: { error: 'Ride request not found' }, status: :not_found unless @request
      end

      def serialize(request)
        request.as_json(except: [:user_id]).merge(
          user: { id: request.user.id, name: request.user.name, verifications: request.user.verifications }
        )
      end
    end
  end
end
