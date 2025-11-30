module Api
  module V1
    class MessagesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_conversation
      before_action :authorize_participant!

      # GET /api/v1/conversations/:conversation_id/messages
      def index
        messages = @conversation.messages.includes(:user).order(created_at: :asc)
        
        render json: messages.as_json(
          include: { user: { only: [:id, :name, :email] } }
        )
      end

      # POST /api/v1/conversations/:conversation_id/messages
      def create
        message = @conversation.messages.build(message_params)
        message.user = current_user

        if message.save
          render json: message.as_json(
            include: { user: { only: [:id, :name, :email] } }
          ), status: :created
        else
          render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/conversations/:conversation_id/messages/:id
      def destroy
        message = @conversation.messages.find(params[:id])
        
        # Solo el autor del mensaje puede eliminarlo
        unless message.user_id == current_user.id
          render json: { error: "You can only delete your own messages" }, status: :forbidden
          return
        end
        
        message.destroy
        render json: { message: "Message deleted successfully" }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Message not found" }, status: :not_found
      end

      private

      def set_conversation
        @conversation = Conversation.find(params[:conversation_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Conversation not found" }, status: :not_found
      end

      def authorize_participant!
        unless @conversation.participant?(current_user)
          render json: { error: "You don't have access to this conversation" }, status: :forbidden
        end
      end

      def message_params
        params.require(:message).permit(:content)
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
