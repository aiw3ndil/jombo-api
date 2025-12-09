FactoryBot.define do
  factory :review do
    association :booking
    association :reviewer, factory: :user
    association :reviewee, factory: :user
    rating { rand(1..5) }
    comment { Faker::Lorem.paragraph }

    trait :excellent do
      rating { 5 }
    end

    trait :poor do
      rating { 1 }
    end

    trait :past_trip do
      after(:build) do |review|
        review.booking.trip.departure_time = 2.days.ago
      end
    end
  end
end
