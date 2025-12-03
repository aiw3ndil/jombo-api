class User < ApplicationRecord
  has_secure_password
  validates :email, presence: true, uniqueness: true
  validates :language, presence: true, inclusion: { in: %w[en es fi] }
  
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
  
  before_validation :set_default_language, on: :create
  
  def average_rating
    reviews_received.average(:rating).to_f.round(2)
  end
  
  def total_reviews
    reviews_received.count
  end
  
  private
  
  def set_default_language
    self.language ||= 'en'
  end
end
