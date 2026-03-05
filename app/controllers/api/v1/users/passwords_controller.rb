module Api
  module V1
    module Users
      class PasswordsController < ApplicationController
        before_action :authenticate_user!

        def update
          unless current_user.authenticate(params[:current_password])
            return render json: { error: "Current password is incorrect" }, status: :unprocessable_entity
          end

          if params[:password] != params[:password_confirmation]
            return render json: { errors: ["Password confirmation doesn't match Password"] }, status: :unprocessable_entity
          end

          if current_user.update(password_params)
            render json: { message: "Password updated successfully" }, status: :ok
          else
            render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
          end
        rescue => e
          Rails.logger.error "Password update error: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
          render json: { 
            error: "Failed to update password", 
            message: e.message 
          }, status: :internal_server_error
        end

        private

        def password_params
          params.permit(:password, :password_confirmation)
        end
      end
    end
  end
end
