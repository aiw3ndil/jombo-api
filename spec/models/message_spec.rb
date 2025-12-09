require 'rails_helper'

RSpec.describe Message, type: :model do
  describe 'associations' do
    it { should belong_to(:conversation) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_most(1000) }
  end

  describe 'default scope' do
    let(:conversation) { create(:conversation) }
    let!(:message1) { create(:message, conversation: conversation, created_at: 2.hours.ago) }
    let!(:message2) { create(:message, conversation: conversation, created_at: 1.hour.ago) }
    let!(:message3) { create(:message, conversation: conversation, created_at: Time.current) }

    it 'orders messages by created_at ascending' do
      messages = conversation.messages
      expect(messages.first).to eq(message1)
      expect(messages.last).to eq(message3)
    end
  end

  describe 'callbacks' do
    let(:conversation) { create(:conversation) }
    let(:sender) { create(:user) }
    let(:recipient1) { create(:user) }
    let(:recipient2) { create(:user) }

    before do
      create(:conversation_participant, conversation: conversation, user: sender)
      create(:conversation_participant, conversation: conversation, user: recipient1)
      create(:conversation_participant, conversation: conversation, user: recipient2)
    end

    it 'notifies participants after creation', skip: 'requires ActionMailer setup' do
      expect {
        create(:message, conversation: conversation, user: sender)
      }.to have_enqueued_mail(UserMailer, :new_message).twice
    end
  end
end
