class User < ApplicationRecord
  has_secure_password validations: false
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true, if: :password_required?
  validates :language, presence: true, inclusion: { in: %w[en fi] }
  validates :region, inclusion: { in: %w[fi] }
  
  # Picture upload
  has_one_attached :picture
  
  has_many :trips, foreign_key: 'driver_id', dependent: :destroy
  has_many :vehicles, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :booked_trips, through: :bookings, source: :trip
  has_many :messages, dependent: :destroy
  has_many :conversation_participants, dependent: :destroy
  has_many :conversations, through: :conversation_participants
  has_many :reviews_given, class_name: 'Review', foreign_key: 'reviewer_id', dependent: :destroy
  has_many :reviews_received, class_name: 'Review', foreign_key: 'reviewee_id', dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :ride_requests, dependent: :destroy
  has_many :search_alerts, dependent: :destroy

  # Teléfono en formato internacional (E.164), p. ej. +358401234567
  validates :phone, format: { with: /\A\+[1-9]\d{6,14}\z/ }, allow_blank: true
  validates :bio, length: { maximum: 500 }

  before_validation :normalize_phone
  before_save :reset_phone_verification, if: :will_save_change_to_phone?
  before_save(if: -> { persisted? && will_save_change_to_email? }) { self.email_verified_at = nil }

  # Nivel de experiencia (viajes como conductor + como pasajero): [nivel, viajes mínimos, valoración mínima]
  EXPERIENCE_LEVELS = [
    ['expert', 25, 4.6],
    ['experienced', 10, 4.4],
    ['regular', 3, 4.0]
  ].freeze
  PHONE_CODE_TTL = 10.minutes
  PHONE_CODE_RESEND_AFTER = 1.minute
  PHONE_CODE_MAX_ATTEMPTS = 5
  
  REGION = 'fi'.freeze

  before_validation :set_default_language, on: :create
  before_validation { self.region = REGION }
  
  def average_rating
    reviews_received.average(:rating).to_f.round(2)
  end
  
  def total_reviews
    reviews_received.count
  end

  # Viajes ya realizados como conductor con al menos un pasajero confirmado
  def completed_trips_count
    trips.where('departure_time < ?', Time.current)
         .where(id: Booking.confirmed.select(:trip_id)).count
  end

  def rides_taken_count
    bookings.confirmed.joins(:trip).where('trips.departure_time < ?', Time.current).count
  end

  def experience_level
    completed = completed_trips_count + rides_taken_count
    rating = average_rating
    level = EXPERIENCE_LEVELS.find { |_name, min_trips, min_rating| completed >= min_trips && rating >= min_rating }
    level ? level.first : 'new'
  end

  def email_verified?
    email_verified_at.present?
  end

  def phone_verified?
    phone.present? && phone_verified_at.present?
  end

  def verifications
    { email: email_verified?, phone: phone_verified?, google: provider == 'google', verified: verified_member? }
  end

  # Miembro verificado: email y, si hay SMS disponible, también teléfono
  def verified_member?
    email_verified? && (phone_verified? || !SmsService.enabled?)
  end

  # Para publicar viajes hace falta el teléfono verificado (si se pueden enviar SMS)
  def can_publish_trips?
    !SmsService.enabled? || phone_verified?
  end

  # Para reservar hace falta el email verificado
  def can_book?
    email_verified?
  end

  def generate_email_verification_token!
    update_columns(email_verification_token: SecureRandom.urlsafe_base64(24))
    email_verification_token
  end

  def verify_email!
    update_columns(email_verified_at: Time.current, email_verification_token: nil)
  end

  # Genera un código de 6 dígitos y guarda solo su hash. Devuelve el código.
  def generate_phone_code!
    code = format('%06d', SecureRandom.random_number(1_000_000))
    update_columns(phone_verification_code_digest: BCrypt::Password.create(code),
                   phone_verification_sent_at: Time.current, phone_verification_attempts: 0)
    code
  end

  def phone_code_recently_sent?
    phone_verification_sent_at.present? && phone_verification_sent_at > PHONE_CODE_RESEND_AFTER.ago
  end

  def verify_phone_code!(code)
    return false if phone_verification_code_digest.blank? || phone_verification_sent_at.nil?
    return false if phone_verification_sent_at < PHONE_CODE_TTL.ago
    return false if phone_verification_attempts >= PHONE_CODE_MAX_ATTEMPTS

    increment!(:phone_verification_attempts)
    return false unless BCrypt::Password.new(phone_verification_code_digest).is_password?(code.to_s.strip)

    update_columns(phone_verified_at: Time.current, phone_verification_code_digest: nil)
    true
  end

  def generate_password_token!
    self.reset_password_token = SecureRandom.urlsafe_base64
    self.reset_password_sent_at = Time.current
    save!
  end

  def password_token_valid?
    (self.reset_password_sent_at + 2.hours) > Time.current
  end

  def reset_password!(password)
    self.reset_password_token = nil
    self.password = password
    save!
  end
  
  private
  
  private

  def password_required?
    provider.blank? && (new_record? || password_digest_changed?)
  end
  
  def normalize_phone
    return if phone.nil?

    digits = phone.to_s.gsub(/[\s\-()]/, '')
    digits = "+358#{digits[1..]}" if digits.start_with?('0') # número finlandés local
    self.phone = digits.presence
  end

  def reset_phone_verification
    self.phone_verified_at = nil
    self.phone_verification_code_digest = nil
  end

  def set_default_language
    self.language ||= 'en'
  end
  
  # Find or create user from OAuth data
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.password = SecureRandom.hex(20) # Random password for OAuth users
      # Download and attach picture if available
      if auth.info.image
        begin
          require 'open-uri'
          downloaded_image = URI.open(auth.info.image)
          user.picture.attach(
            io: downloaded_image,
            filename: "profile_#{auth.provider}_#{auth.uid}.jpg"
          )
        rescue => e
          Rails.logger.error "Failed to download profile picture: #{e.message}"
        end
      end
    end
  end
end
