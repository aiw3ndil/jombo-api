FactoryBot.define do
  factory :conversation_participant do
    association :conversation
    association :user
  end
end
