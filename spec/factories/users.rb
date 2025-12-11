FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    sequence(:name) { |n| "User #{n}" }
    language { 'en' }

    trait :spanish do
      language { 'es' }
    end

    trait :finnish do
      language { 'fi' }
    end

  end
end
