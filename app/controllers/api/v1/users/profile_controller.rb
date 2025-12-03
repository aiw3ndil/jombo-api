module Api
  module V1
    module Users
      class ProfileController < ApplicationController
        before_action :authenticate_user!

        def update
          begin
            if current_user.update(profile_params)
              render json: {
                message: "Profile updated successfully",
                user: user_json(current_user)
              }, status: :ok
            else
              render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
            end
          rescue => e
            Rails.logger.error "Profile update error: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
            render json: { 
              error: "Failed to update profile", 
              message: e.message 
            }, status: :internal_server_error
          end
        end

        private

        def authenticate_user!
          token = request.cookies["jwt"]
          payload = JwtService.decode(token)

          if payload
            @current_user = User.find_by(id: payload["user_id"] || payload[:user_id])
            unless @current_user
              render json: { error: "Unauthorized" }, status: :unauthorized
            end
          else
            render json: { error: "Unauthorized" }, status: :unauthorized
          end
        end

        def current_user
          @current_user
        end

        def profile_params
          params.permit(:name, :email, :language, :picture)
        end

        def user_json(user)
          {
            id: user.id,
            email: user.email,
            name: user.name,
            language: user.language,
            picture_url: user.picture.attached? ? url_for(user.picture) : nil
          }
        end
      end
    end
  end
end
