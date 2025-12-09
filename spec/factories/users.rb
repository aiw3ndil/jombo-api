FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    sequence(:name) { |n| "User #{n}" }
    language { 'en' }
    phone { Faker::PhoneNumber.cell_phone }
    bio { Faker::Lorem.paragraph }

    trait :spanish do
      language { 'es' }
    end

    trait :finnish do
      language { 'fi' }
    end

    trait :without_phone do
      phone { nil }
    end
  end
end
