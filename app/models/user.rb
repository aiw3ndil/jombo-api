class User < ApplicationRecord
  has_secure_password
  validates :email, presence: true, uniqueness: true
  
  has_many :trips, foreign_key: 'driver_id', dependent: :destroy
end
