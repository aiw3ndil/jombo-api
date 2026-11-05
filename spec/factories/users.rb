FactoryBot.define do
  factory :user do
    transient do
      # Por defecto: email y teléfono verificados (requisitos para reservar y publicar)
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

    # El teléfono se asigna con update_columns porque guardar un teléfono nuevo
    # resetea su verificación.
    after(:create) do |user, evaluator|
      next unless evaluator.verified

      user.update_columns(email_verified_at: Time.current,
                          phone: user.phone || "+35840#{format('%07d', user.id)}",
                          phone_verified_at: Time.current)
    end
  end
end
