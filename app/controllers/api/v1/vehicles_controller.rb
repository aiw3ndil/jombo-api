module Api
  module V1
    class VehiclesController < ApplicationController
      VEHICLE_PERMITTED = %i[brand model vehicle_type color doors seats year fuel_type].freeze

      before_action :authenticate_user!
      before_action :set_vehicle, only: [:show, :update, :destroy]

      def index
        render json: current_user.vehicles.order(created_at: :desc)
      end

      def show
        render json: @vehicle
      end

      def create
        vehicle = current_user.vehicles.build(vehicle_params)
        if vehicle.save
          render json: vehicle, status: :created
        else
          render json: { errors: vehicle.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @vehicle.update(vehicle_params)
          render json: @vehicle
        else
          render json: { errors: @vehicle.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @vehicle.destroy
        render json: { message: "Vehicle deleted successfully" }
      end

      private

      def set_vehicle
        @vehicle = current_user.vehicles.find_by(id: params[:id])
        render json: { error: "Vehicle not found" }, status: :not_found unless @vehicle
      end

      def vehicle_params
        params.require(:vehicle).permit(*VEHICLE_PERMITTED)
      end
    end
  end
end
