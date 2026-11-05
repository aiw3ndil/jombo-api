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
  has_many :reports_made, class_name: 'Report', foreign_key: 'reporter_id', dependent: :destroy
  has_many :reports_received, class_name: 'Report', foreign_key: 'reported_id', dependent: :destroy
  has_many :blocks_made, class_name: 'Block', foreign_key: 'blocker_id', dependent: :destroy
  has_many :blocks_received, class_name: 'Block', foreign_key: 'blocked_id', dependent: :destroy

  validates :bio, length: { maximum: 500 }

  before_save(if: -> { persisted? && will_save_change_to_email? }) { self.email_verified_at = nil }

  # Nivel de experiencia (viajes como conductor + como pasajero): [nivel, viajes mínimos, valoración mínima]
  EXPERIENCE_LEVELS = [
    ['expert', 25, 4.6],
    ['experienced', 10, 4.4],
    ['regular', 3, 4.0]
  ].freeze
  
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

  # ¿Hay un bloqueo entre los dos usuarios (en cualquier dirección)?
  def blocked_with?(other)
    return false unless other

    Block.where(blocker_id: id, blocked_id: other.id).or(Block.where(blocker_id: other.id, blocked_id: id)).exists?
  end

  # Ids de usuarios con los que hay un bloqueo en cualquier dirección
  def blocked_user_ids
    Block.where(blocker_id: id).pluck(:blocked_id) | Block.where(blocked_id: id).pluck(:blocker_id)
  end

  # Fiabilidad como conductor en los últimos 12 meses (nil si hay menos de 3 datos)
  RELIABILITY_MIN_SAMPLES = 3

  # % de reservas canceladas por el conductor sobre las que llegó a tener
  def driver_cancellation_rate
    scope = Booking.joins(:trip).where(trips: { driver_id: id }).where('bookings.created_at > ?', 12.months.ago)
    total = scope.where("bookings.status = 'confirmed' OR bookings.cancelled_by = 'driver'").count
    return nil if total < RELIABILITY_MIN_SAMPLES

    (scope.where(cancelled_by: 'driver').count * 100.0 / total).round
  end

  # Mediana de horas que tarda en responder a solicitudes (sin contar la reserva instantánea)
  def median_response_hours
    hours = Booking.joins(:trip).where(trips: { driver_id: id, instant_booking: false })
                   .where.not(responded_at: nil).where('bookings.created_at > ?', 12.months.ago)
                   .pluck(Arel.sql('EXTRACT(EPOCH FROM (bookings.responded_at - bookings.created_at)) / 3600.0'))
                   .map(&:to_f).sort
    return nil if hours.size < RELIABILITY_MIN_SAMPLES

    mid = hours.size / 2
    median = hours.size.odd? ? hours[mid] : (hours[mid - 1] + hours[mid]) / 2
    median.round(1)
  end

  def reliability
    { cancellation_rate: driver_cancellation_rate, response_hours: median_response_hours }
  end

  def email_verified?
    email_verified_at.present?
  end

  def verifications
    # Sin el proveedor de login (p. ej. Google): es dato privado
    { email: email_verified?, verified: verified_member? }
  end

  # Miembro verificado: email confirmado
  def verified_member?
    email_verified?
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
