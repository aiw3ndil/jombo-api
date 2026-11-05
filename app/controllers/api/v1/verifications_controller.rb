module Api
  module V1
    # Verificación de email (enlace por correo)
    class VerificationsController < ApplicationController
      before_action :authenticate_user!, except: [:confirm_email]

      # POST /api/v1/verification/email — reenvía el enlace
      def send_email
        return render json: { message: 'Email already verified' } if current_user.email_verified?

        current_user.generate_email_verification_token!
        UserMailer.email_verification(current_user).deliver_later
        render json: { message: 'Verification email sent' }
      end

      # POST /api/v1/verification/email/confirm { token }
      def confirm_email
        user = params[:token].present? && User.find_by(email_verification_token: params[:token].to_s)
        return render json: { error: 'Invalid or expired link' }, status: :unprocessable_entity unless user

        user.verify_email!
        render json: { message: 'Email verified', verifications: user.verifications }
      end
    end
  end
end
