class User < ApplicationRecord
  has_secure_password validations: false
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, presence: true, if: :password_required?
  validates :language, presence: true, inclusion: { in: %w[en es fi] }
  validates :region, inclusion: { in: %w[es fi], allow_nil: true }
  
  # Picture upload
  has_one_attached :picture
  
  has_many :trips, foreign_key: 'driver_id', dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :booked_trips, through: :bookings, source: :trip
  has_many :messages, dependent: :destroy
  has_many :conversation_participants, dependent: :destroy
  has_many :conversations, through: :conversation_participants
  has_many :reviews_given, class_name: 'Review', foreign_key: 'reviewer_id', dependent: :destroy
  has_many :reviews_received, class_name: 'Review', foreign_key: 'reviewee_id', dependent: :destroy
  has_many :notifications, dependent: :destroy
  
  before_validation :set_default_language, on: :create
  
  def average_rating
    reviews_received.average(:rating).to_f.round(2)
  end
  
  def total_reviews
    reviews_received.count
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
