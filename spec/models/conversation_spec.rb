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
    let(:driver) { create(:user) }
    let(:passenger) { create(:user) }
    let(:trip) { create(:trip, driver: driver) }
    let!(:booking) { create(:booking, :confirmed, trip: trip, user: passenger) }
    let(:conversation) { create(:conversation, trip: trip) }

    it 'returns true for the driver' do
      expect(conversation.participant?(driver)).to be true
    end

    it 'returns true for a passenger with a confirmed booking' do
      expect(conversation.participant?(passenger)).to be true
    end

    it 'returns false for other users' do
      other_user = create(:user)
      expect(conversation.participant?(other_user)).to be false
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
    end
  end
end
