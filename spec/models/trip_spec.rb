require 'rails_helper'

RSpec.describe Trip, type: :model do
  describe 'associations' do
    it { should belong_to(:driver).class_name('User') }
    it { should have_many(:bookings).dependent(:destroy) }
    it { should have_one(:conversation) }
  end

  describe 'validations' do
    it { should validate_presence_of(:departure_location) }
    it { should validate_presence_of(:arrival_location) }
    it { should validate_presence_of(:departure_time) }
    it { should validate_presence_of(:available_seats) }
    it { should validate_numericality_of(:available_seats).is_greater_than_or_equal_to(0).only_integer }
    it { should validate_presence_of(:price) }
    it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
  end

  describe 'scopes' do
    let!(:upcoming_trip) { create(:trip, departure_time: 2.days.from_now) }
    let!(:past_trip) { create(:trip, :past) }

    describe '.upcoming' do
      it 'returns only upcoming trips' do
        trips = Trip.where('departure_time > ?', Time.current)
        expect(trips).to include(upcoming_trip)
        expect(trips).not_to include(past_trip)
      end
    end

    describe '.available' do
      let!(:full_trip) { create(:trip, :full) }

      it 'returns trips with available seats' do
        trips = Trip.where('available_seats > 0')
        expect(trips).to include(upcoming_trip)
        expect(trips).not_to include(full_trip)
      end
    end
  end

  describe '#ensure_conversation' do
    let(:trip) { create(:trip) }

    context 'when conversation does not exist' do
      it 'creates a new conversation' do
        expect {
          trip.ensure_conversation
        }.to change(Conversation, :count).by(1)
      end

      it 'returns the conversation' do
        conversation = trip.ensure_conversation
        expect(conversation).to be_a(Conversation)
        expect(conversation.trip).to eq(trip)
      end
    end

    context 'when conversation already exists' do
      let!(:existing_conversation) { create(:conversation, trip: trip) }

      it 'does not create a new conversation' do
        expect {
          trip.ensure_conversation
        }.not_to change(Conversation, :count)
      end

      it 'returns the existing conversation' do
        conversation = trip.ensure_conversation
        expect(conversation).to eq(existing_conversation)
      end
    end
  end
end
