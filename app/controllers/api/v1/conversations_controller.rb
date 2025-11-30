module Api
  module V1
    class ConversationsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_conversation, only: [:show, :destroy]
      before_action :authorize_participant!, only: [:show, :destroy]

      # GET /api/v1/conversations
      def index
        # Conversaciones donde el usuario es participante
        conversations = current_user.conversations
                                    .includes(:trip, :participants, :messages)
                                    .order('messages.created_at DESC')
        
        render json: conversations.as_json(
          include: {
            trip: {
              only: [:id, :departure_location, :arrival_location, :departure_time],
              include: {
                driver: { only: [:id, :name, :email] }
              }
            },
            participants: { only: [:id, :name, :email] },
            last_message: {
              only: [:id, :content, :created_at],
              include: { user: { only: [:id, :name] } }
            }
          }
        )
      end

      # GET /api/v1/conversations/:id
      def show
        messages = @conversation.messages.includes(:user).order(created_at: :asc)
        
        render json: {
          conversation: @conversation.as_json(
            include: {
              trip: {
                only: [:id, :departure_location, :arrival_location, :departure_time],
                include: { driver: { only: [:id, :name, :email] } }
              },
              participants: { only: [:id, :name, :email] }
            }
          ),
          messages: messages.as_json(
            include: { user: { only: [:id, :name, :email] } }
          )
        }
      end

      # GET /api/v1/trips/:trip_id/conversation
      def show_by_trip
        trip = Trip.find(params[:trip_id])
        
        # Verificar que el usuario puede acceder a esta conversación
        unless can_access_trip_conversation?(trip)
          render json: { error: "You don't have access to this conversation" }, status: :forbidden
          return
        end
        
        conversation = trip.conversation
        
        unless conversation
          render json: { error: "No conversation found for this trip" }, status: :not_found
          return
        end
        
        # Redirigir al show de la conversación
        @conversation = conversation
        show
      end

      # DELETE /api/v1/conversations/:id
      def destroy
        # Solo el conductor puede eliminar la conversación
        unless @conversation.trip.driver_id == current_user.id
          render json: { error: "Only the driver can delete the conversation" }, status: :forbidden
          return
        end
        
        @conversation.destroy
        render json: { message: "Conversation deleted successfully" }
      end

      private

      def set_conversation
        @conversation = Conversation.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Conversation not found" }, status: :not_found
      end

      def authorize_participant!
        unless @conversation.participant?(current_user)
          render json: { error: "You don't have access to this conversation" }, status: :forbidden
        end
      end
      
      def can_access_trip_conversation?(trip)
        # El conductor siempre puede acceder
        return true if trip.driver_id == current_user.id
        
        # Los pasajeros con reservas confirmadas pueden acceder
        trip.bookings.confirmed.exists?(user_id: current_user.id)
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
    end
  end
end
