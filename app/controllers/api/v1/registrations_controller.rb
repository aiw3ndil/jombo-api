module Api
  module V1
    class RegistrationsController < ApplicationController
      def create
        user = User.new(registration_params)

        if user.save
          # Enviar email de bienvenida
          UserMailer.welcome_email(user).deliver_later
          
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
          render json: { 
            message: "User created successfully", 
            user: { id: user.id, email: user.email, name: user.name, language: user.language } 
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def registration_params
        params.require(:user).permit(:email, :password, :password_confirmation, :name, :language)
      end
    end
  end
end
