FactoryBot.define do
  factory :trip do
    association :driver, factory: :user
    departure_location { Faker::Address.city }
    arrival_location { Faker::Address.city }
    departure_time { 2.days.from_now }
    available_seats { 3 }
    price { rand(10.0..50.0).round(2) }
    description { Faker::Lorem.paragraph }

    trait :full do
      available_seats { 0 }
    end

    trait :past do
      departure_time { 2.days.ago }
    end

    trait :today do
      departure_time { Time.current }
    end
  end
end
