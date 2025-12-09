FactoryBot.define do
  factory :booking do
    association :user
    association :trip
    seats { 1 }
    status { 'pending' }

    trait :confirmed do
      status { 'confirmed' }
    end

    trait :rejected do
      status { 'rejected' }
    end

    trait :cancelled do
      status { 'cancelled' }
    end
  end
end
