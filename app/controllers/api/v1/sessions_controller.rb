module Api
  module V1
    class SessionsController < ApplicationController
      def create
        user = User.find_by(email: session_params[:email])

        if user&.authenticate(session_params[:password])
          token = JwtService.encode(user_id: user.id)

          cookie_opts = {
            value: token,
            httponly: true,
            secure: Rails.env.production?,
            same_site: Rails.env.production? ? :none : :lax,
            expires: 2.hours.from_now,
            path: "/"
          }

          response.set_cookie("jwt", cookie_opts)
          render json: { message: "Logged in" }
        else
          render json: { error: "Invalid credentials" }, status: :unauthorized
        end
      end

      def destroy
        response.delete_cookie("jwt", path: "/")
        render json: { message: "Logged out successfully" }
      end

      def me
        token = request.cookies["jwt"]
        payload = JwtService.decode(token)

        if payload
          user = User.find_by(id: payload["user_id"] || payload[:user_id])
          if user
            render json: { 
              id: user.id, 
              email: user.email, 
              name: user.name,
              language: user.language,
              picture_url: user.picture.attached? ? url_for(user.picture) : nil
            }
          else
            render json: { error: "Unauthorized" }, status: :unauthorized
          end
        else
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      private

      def session_params
        params.require(:user).permit(:email, :password, :picture)
      end

    end
  end
end
