require 'net/http'

# Envío de SMS. Usa Twilio si están configuradas TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN y
# TWILIO_FROM; si no, en desarrollo y test escribe el mensaje en el log.
class SmsService
  class DeliveryError < StandardError; end

  # Mensajes enviados en test (para las specs)
  cattr_accessor :deliveries, default: []

  class << self
    def enabled?
      twilio_configured? || !Rails.env.production?
    end

    def deliver(to:, body:)
      if twilio_configured?
        deliver_with_twilio(to, body)
      elsif Rails.env.production?
        raise DeliveryError, 'SMS provider is not configured'
      else
        Rails.logger.info("[SMS to #{to}] #{body}")
        deliveries << { to: to, body: body } if Rails.env.test?
      end
      true
    end

    private

    def twilio_configured?
      %w[TWILIO_ACCOUNT_SID TWILIO_AUTH_TOKEN TWILIO_FROM].all? { |key| ENV[key].present? }
    end

    def deliver_with_twilio(to, body)
      sid = ENV.fetch('TWILIO_ACCOUNT_SID')
      uri = URI("https://api.twilio.com/2010-04-01/Accounts/#{sid}/Messages.json")
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(sid, ENV.fetch('TWILIO_AUTH_TOKEN'))
      request.set_form_data('To' => to, 'From' => ENV.fetch('TWILIO_FROM'), 'Body' => body)

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
        http.request(request)
      end
      return if response.is_a?(Net::HTTPSuccess)

      Rails.logger.error("Twilio error #{response.code}: #{response.body}")
      raise DeliveryError, 'Could not send the SMS'
    end
  end
end
