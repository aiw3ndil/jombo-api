# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# db/seeds.rb

user1 = User.create!(
  email: "juan@example.com",
  password: "password123",
  name: "Juan Pérez"
)

user2 = User.create!(
  email: "maria@example.com",
  password: "secret456",
  name: "María Gómez"
)

# Create 5 example trips
Trip.create!(
  driver: user1,
  departure_location: "Madrid",
  arrival_location: "Barcelona",
  departure_time: 2.days.from_now,
  available_seats: 3,
  price: 25.50
)

Trip.create!(
  driver: user2,
  departure_location: "Valencia",
  arrival_location: "Madrid",
  departure_time: 1.day.from_now,
  available_seats: 4,
  price: 20.00
)

Trip.create!(
  driver: user1,
  departure_location: "Barcelona",
  arrival_location: "Valencia",
  departure_time: 3.days.from_now,
  available_seats: 2,
  price: 30.00
)

Trip.create!(
  driver: user2,
  departure_location: "Sevilla",
  arrival_location: "Granada",
  departure_time: 4.days.from_now,
  available_seats: 3,
  price: 15.75
)

Trip.create!(
  driver: user1,
  departure_location: "Madrid",
  arrival_location: "Sevilla",
  departure_time: 5.days.from_now,
  available_seats: 4,
  price: 35.00
)
