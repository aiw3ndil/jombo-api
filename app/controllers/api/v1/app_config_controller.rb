module Api
  module V1
    # Configuración pública que necesita el frontend
    class AppConfigController < ApplicationController
      def show
        render json: {
          suggested_price_per_km: Trip::SUGGESTED_PRICE_PER_KM,
          max_price_per_km: Trip::MAX_PRICE_PER_KM
        }
      end
    end
  end
end
