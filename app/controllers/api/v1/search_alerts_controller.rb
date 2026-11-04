module Api
  module V1
    # Alertas de búsqueda del usuario
    class SearchAlertsController < ApplicationController
      before_action :authenticate_user!

      def index
        render json: current_user.search_alerts.order(created_at: :desc)
      end

      def create
        alert = current_user.search_alerts.build(params.require(:search_alert).permit(:departure_location, :arrival_location, :date))
        if alert.save
          render json: alert, status: :created
        else
          render json: { errors: alert.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        alert = current_user.search_alerts.find_by(id: params[:id])
        return render json: { error: 'Alert not found' }, status: :not_found unless alert

        alert.destroy
        head :no_content
      end
    end
  end
end
