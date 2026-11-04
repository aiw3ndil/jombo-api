FactoryBot.define do
  factory :vehicle do
    association :user
    brand { 'Toyota' }
    model { 'Corolla' }
    vehicle_type { 'hatchback' }
    color { 'Blue' }
    doors { 5 }
    seats { 5 }
    year { 2020 }
    fuel_type { 'hybrid' }
  end
end
