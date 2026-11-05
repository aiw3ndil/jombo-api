module Api
  module V1
    # Verificación de email (enlace por correo) y teléfono (código por SMS)
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

      # POST /api/v1/verification/phone — envía un código al teléfono del perfil
      def send_phone
        return render json: { error: 'SMS verification is not available' }, status: :service_unavailable unless SmsService.enabled?
        return render json: { error: 'Add a phone number to your profile first' }, status: :unprocessable_entity if current_user.phone.blank?
        return render json: { message: 'Phone already verified' } if current_user.phone_verified?
        if current_user.phone_code_recently_sent?
          return render json: { error: 'Please wait a minute before requesting a new code' }, status: :too_many_requests
        end

        code = current_user.generate_phone_code!
        I18n.with_locale(current_user.language) do
          SmsService.deliver(to: current_user.phone, body: I18n.t('sms.verification_code', code: code))
        end
        render json: { message: 'Code sent' }
      rescue SmsService::DeliveryError => e
        # El SMS no salió: anulamos el código para que se pueda reintentar sin esperar
        current_user.update_columns(phone_verification_sent_at: nil, phone_verification_code_digest: nil)
        render json: { error: e.message }, status: :bad_gateway
      end

      # POST /api/v1/verification/phone/confirm { code }
      def confirm_phone
        if current_user.verify_phone_code!(params[:code])
          render json: { message: 'Phone verified', verifications: current_user.verifications }
        else
          render json: { error: 'Invalid or expired code' }, status: :unprocessable_entity
        end
      end
    end
  end
end
