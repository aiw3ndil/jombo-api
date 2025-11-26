require 'jwt'  # 🔹 asegúrate de requerir la gema

class JwtService
  SECRET = Rails.application.secret_key_base

  def self.encode(payload, exp = 2.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET)[0]
    HashWithIndifferentAccess.new decoded
  rescue
    nil
  end
end
