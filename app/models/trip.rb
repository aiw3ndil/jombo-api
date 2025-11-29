class Trip < ApplicationRecord
  belongs_to :driver, class_name: 'User', foreign_key: 'driver_id'
  has_many :bookings, dependent: :destroy
  has_many :passengers, through: :bookings, source: :user
  
  validates :departure_location, :arrival_location, :departure_time, :available_seats, :price, presence: true
  validates :available_seats, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
end
