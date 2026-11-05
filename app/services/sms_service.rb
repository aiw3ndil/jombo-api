require 'net/http'

# Envío de SMS a través de textbee (https://textbee.dev): un móvil Android con la app de
# textbee hace de pasarela y envía los SMS con su propia SIM.
#
# Variables de entorno:
#   TEXTBEE_API_KEY    (obligatoria) clave de la API, del panel de textbee
#   TEXTBEE_DEVICE_ID  (opcional) móvil concreto; si no, textbee usa el dispositivo por defecto
#   TEXTBEE_API_URL    (opcional) para textbee autoalojado; por defecto https://api.textbee.dev
#
# Sin TEXTBEE_API_KEY: en desarrollo y test el mensaje se escribe en el log; en producción
# la verificación por SMS queda desactivada.
class SmsService
  class DeliveryError < StandardError; end

  DEFAULT_API_URL = 'https://api.textbee.dev'.freeze

  # Mensajes enviados en test (para las specs)
  cattr_accessor :deliveries, default: []

  class << self
    def enabled?
      configured? || !Rails.env.production?
    end

    def deliver(to:, body:)
      if configured?
        deliver_with_textbee(to, body)
      elsif Rails.env.production?
        raise DeliveryError, 'SMS provider is not configured'
      else
        Rails.logger.info("[SMS to #{to}] #{body}")
        deliveries << { to: to, body: body } if Rails.env.test?
      end
      true
    end

    private

    def configured?
      ENV['TEXTBEE_API_KEY'].present?
    end

    def deliver_with_textbee(to, body)
      base = ENV['TEXTBEE_API_URL'].presence || DEFAULT_API_URL
      uri = URI("#{base.chomp('/')}/api/v1/gateway/send-sms")
      payload = { recipients: [to], message: body }
      payload[:deviceId] = ENV['TEXTBEE_DEVICE_ID'] if ENV['TEXTBEE_DEVICE_ID'].present?

      request = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json',
                                         'x-api-key' => ENV.fetch('TEXTBEE_API_KEY'))
      request.body = payload.to_json

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                                     open_timeout: 5, read_timeout: 10) do |http|
        http.request(request)
      end
      return if response.is_a?(Net::HTTPSuccess)

      Rails.logger.error("textbee error #{response.code}: #{response.body}")
      raise DeliveryError, "Could not send the SMS (textbee #{response.code})"
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED => e
      Rails.logger.error("textbee connection error: #{e.class}: #{e.message}")
      raise DeliveryError, 'Could not send the SMS (gateway unreachable)'
    end
  end
end
