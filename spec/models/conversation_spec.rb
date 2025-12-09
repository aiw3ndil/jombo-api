require 'rails_helper'

RSpec.describe Conversation, type: :model do
  describe 'associations' do
    it { should belong_to(:trip) }
    it { should have_many(:messages) }
    it { should have_many(:conversation_participants) }
    it { should have_many(:participants).through(:conversation_participants) }
  end

  describe 'validations' do
    subject { create(:conversation) }
    it { should validate_uniqueness_of(:trip_id) }
  end

  describe '#participant?' do
    let(:conversation) { create(:conversation) }
    let(:participant) { create(:user) }
    let(:non_participant) { create(:user) }

    before do
      create(:conversation_participant, conversation: conversation, user: participant)
    end

    it 'returns true for participants' do
      expect(conversation.participant?(participant)).to be true
    end

    it 'returns false for non-participants' do
      expect(conversation.participant?(non_participant)).to be false
    end
  end

  describe '#add_participant' do
    let(:conversation) { create(:conversation) }
    let(:user) { create(:user) }

    context 'when user is not a participant' do
      it 'adds user as participant' do
        expect {
          conversation.add_participant(user)
        }.to change { conversation.participants.count }.by(1)
      end

      it 'returns true' do
        expect(conversation.add_participant(user)).to be true
      end
    end

    context 'when user is already a participant' do
      before do
        create(:conversation_participant, conversation: conversation, user: user)
      end

      it 'does not add user again' do
        expect {
          conversation.add_participant(user)
        }.not_to change { conversation.participants.count }
      end

      it 'returns false' do
        expect(conversation.add_participant(user)).to be false
      end
    end
  end
end
