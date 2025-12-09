FactoryBot.define do
  factory :message do
    association :conversation
    association :user
    content { Faker::Lorem.sentence }

    trait :long do
      content { Faker::Lorem.paragraph(sentence_count: 10) }
    end
  end
end
