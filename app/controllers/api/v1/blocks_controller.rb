module Api
  module V1
    # Bloquear y desbloquear usuarios
    class BlocksController < ApplicationController
      before_action :authenticate_user!
      before_action :set_user

      # POST /api/v1/users/:user_id/block
      def create
        block = current_user.blocks_made.find_or_initialize_by(blocked: @user)
        if block.save
          render json: { blocked: true }, status: :created
        else
          render json: { errors: block.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/users/:user_id/block
      def destroy
        current_user.blocks_made.where(blocked: @user).destroy_all
        render json: { blocked: false }
      end

      private

      def set_user
        @user = User.find_by(id: params[:user_id])
        render json: { error: 'User not found' }, status: :not_found unless @user
      end
    end
  end
end
