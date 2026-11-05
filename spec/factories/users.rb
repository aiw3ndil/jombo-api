FactoryBot.define do
  factory :user do
    transient do
      # Por defecto: email verificado (requisito para reservar)
      verified { true }
    end

    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    password_confirmation { 'password123' }
    sequence(:name) { |n| "User #{n}" }
    language { 'en' }
    region { 'fi' }

    trait :finnish do
      language { 'fi' }
    end

    trait :unverified do
      verified { false }
    end

    after(:create) do |user, evaluator|
      user.update_columns(email_verified_at: Time.current) if evaluator.verified
    end
  end
end
