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
  email: "matti@example.com",
  password: "password123",
  name: "Matti Virtanen"
)

user2 = User.create!(
  email: "aino@example.com",
  password: "secret456",
  name: "Aino Korhonen"
)

car1 = user1.vehicles.create!(brand: "Toyota", model: "Corolla", vehicle_type: "hatchback", color: "White", doors: 5, seats: 5, year: 2021, fuel_type: "hybrid")
car2 = user2.vehicles.create!(brand: "Volvo", model: "V60", vehicle_type: "estate", color: "Black", doors: 5, seats: 5, year: 2019, fuel_type: "diesel")

# Create 5 example trips
Trip.create!(
  driver: user1,
  vehicle: car1,
  departure_location: "Helsinki",
  arrival_location: "Tampere",
  departure_time: 2.days.from_now,
  available_seats: 3,
  price: 25.50,
  region: "fi"
)

Trip.create!(
  driver: user2,
  vehicle: car2,
  departure_location: "Turku",
  arrival_location: "Helsinki",
  departure_time: 1.day.from_now,
  available_seats: 4,
  price: 20.00,
  region: "fi"
)

Trip.create!(
  driver: user1,
  vehicle: car1,
  departure_location: "Tampere",
  arrival_location: "Jyväskylä",
  departure_time: 3.days.from_now,
  available_seats: 2,
  price: 30.00,
  region: "fi"
)

Trip.create!(
  driver: user2,
  vehicle: car2,
  departure_location: "Oulu",
  arrival_location: "Rovaniemi",
  departure_time: 4.days.from_now,
  available_seats: 3,
  price: 15.75,
  region: "fi"
)

Trip.create!(
  driver: user1,
  vehicle: car1,
  departure_location: "Helsinki",
  arrival_location: "Turku",
  departure_time: 5.days.from_now,
  available_seats: 4,
  price: 35.00,
  region: "fi"
)

# Viaje con paradas intermedias, preferencias y reserva instantánea
departure = 2.days.from_now.change(hour: 8)
long_trip = Trip.new(
  driver: user2,
  vehicle: car2,
  departure_location: "Helsinki",
  arrival_location: "Oulu",
  departure_time: departure,
  available_seats: 3,
  price: 39.00,
  distance_km: 610,
  duration_minutes: 420,
  instant_booking: true,
  pets_allowed: true,
  music_allowed: true,
  max_two_back: true,
  chattiness: "chatty",
  luggage_size: "large",
  description: "Coffee break in Jyväskylä. Small dogs welcome!",
  region: "fi"
)
long_trip.assign_stops([
  { location: "Tampere", departure_time: departure + 2.hours, price_from_origin: 12 },
  { location: "Jyväskylä", departure_time: departure + 4.hours, price_from_origin: 20 }
])
long_trip.save!

user1.update!(bio: "Driving between Helsinki and Turku most weekends. Podcasts and coffee stops.")

RideRequest.create!(
  user: user1,
  departure_location: "Helsinki",
  arrival_location: "Kuopio",
  departure_date: 6.days.from_now.to_date,
  flexible_days: 1,
  seats: 1,
  note: "Small backpack only, can meet anywhere in the centre."
)

SearchAlert.create!(user: user1, departure_location: "Tampere", arrival_location: "Oulu")
