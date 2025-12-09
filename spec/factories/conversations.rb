FactoryBot.define do
  factory :conversation do
    association :trip

    trait :with_participants do
      after(:create) do |conversation|
        create_list(:conversation_participant, 2, conversation: conversation)
      end
    end
  end
end
