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
  
  before_validation :set_default_language, on: :create
  
  private
  
  def set_default_language
    self.language ||= 'en'
  end
end
