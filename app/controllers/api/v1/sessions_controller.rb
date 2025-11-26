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
            secure: Rails.env.production?,              # true en producción HTTPS
            same_site: Rails.env.production? ? :none : :lax, # en prod: none (cross-site), en dev: lax
            expires: 2.hours.from_now,
            path: "/"
          }

          # Si necesitas cookie para subdominios en producción:
          # cookie_opts[:domain] = ".tudominio.com" if Rails.env.production?

          response.set_cookie("jwt", cookie_opts)
          render json: { message: "Logged in" }
        else
          render json: { error: "Invalid credentials" }, status: :unauthorized
        end
      end

      def destroy
        response.delete_cookie("jwt", path: "/")
        render json: { message: "Logged out" }
      end

      def me
        token = request.cookies["jwt"]
        payload = JwtService.decode(token)

        if payload
          user = User.find_by(id: payload["user_id"] || payload[:user_id])
          if user
            render json: { id: user.id, email: user.email, name: user.name }
          else
            render json: { error: "Unauthorized" }, status: :unauthorized
          end
        else
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      end

      private

      # Aquí definimos los parámetros permitidos
      def session_params
        params.require(:user).permit(:email, :password)
      end

    end
  end
end
