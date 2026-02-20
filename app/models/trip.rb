class Trip < ApplicationRecord
  belongs_to :driver, class_name: 'User', foreign_key: 'driver_id'
  has_many :bookings, dependent: :destroy
  has_many :passengers, through: :bookings, source: :user
  has_one :conversation, dependent: :destroy
  
  validates :departure_location, :arrival_location, :departure_time, :available_seats, :price, :region, presence: true
  validates :available_seats, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :region, inclusion: { in: %w[es fi] }
  
  # Crear conversación automáticamente si no existe
  def ensure_conversation
    conversation || create_conversation
  end
end
