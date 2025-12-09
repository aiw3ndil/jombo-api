require 'rails_helper'

RSpec.describe Booking, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:trip) }
    it { should have_many(:reviews).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:seats) }
    it { should validate_numericality_of(:seats).only_integer.is_greater_than(0) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[pending confirmed rejected cancelled]) }

    describe 'not_driver validation' do
      let(:driver) { create(:user) }
      let(:trip) { create(:trip, driver: driver) }

      it 'does not allow driver to book their own trip' do
        booking = build(:booking, user: driver, trip: trip)
        expect(booking).not_to be_valid
        expect(booking.errors[:user]).to include("cannot book their own trip")
      end

      it 'allows other users to book' do
        other_user = create(:user)
        booking = build(:booking, user: other_user, trip: trip)
        expect(booking).to be_valid
      end
    end
  end

  describe 'callbacks' do
    describe 'before_create' do
      it 'sets default status to pending' do
        booking = build(:booking, status: nil)
        booking.save
        expect(booking.status).to eq('pending')
      end
    end
  end

  describe '#confirm_by_driver!' do
    let(:trip) { create(:trip, available_seats: 3) }
    let(:booking) { create(:booking, trip: trip, seats: 2, status: 'pending') }

    context 'when booking is pending' do
      context 'with enough available seats' do
        it 'confirms the booking' do
          booking.confirm_by_driver!
          expect(booking.reload.status).to eq('confirmed')
        end

        it 'decrements available seats' do
          expect {
            booking.confirm_by_driver!
          }.to change { trip.reload.available_seats }.from(3).to(1)
        end

        it 'adds users to conversation' do
          booking.confirm_by_driver!
          conversation = trip.reload.conversation
          expect(conversation).to be_present
          expect(conversation.participants).to include(booking.user, trip.driver)
        end
      end

      context 'without enough available seats' do
        let(:booking) { create(:booking, trip: trip, seats: 5) }

        it 'does not confirm booking' do
          booking.confirm_by_driver!
          expect(booking.reload.status).to eq('pending')
        end

        it 'does not change available seats' do
          expect {
            booking.confirm_by_driver!
          }.not_to change { trip.reload.available_seats }
        end
      end
    end

    context 'when booking is not pending' do
      let(:booking) { create(:booking, :confirmed, trip: trip) }

      it 'returns false' do
        expect(booking.confirm_by_driver!).to be false
      end
    end
  end

  describe '#reject_by_driver!' do
    let(:booking) { create(:booking, status: 'pending') }

    context 'when booking is pending' do
      it 'rejects the booking' do
        booking.reject_by_driver!
        expect(booking.reload.status).to eq('rejected')
      end
    end

    context 'when booking is not pending' do
      let(:booking) { create(:booking, :confirmed) }

      it 'returns false' do
        expect(booking.reject_by_driver!).to be false
      end
    end
  end

  describe '#cancel_by_passenger!' do
    context 'when booking is confirmed' do
      let(:trip) { create(:trip, available_seats: 1) }
      let(:booking) { create(:booking, :confirmed, trip: trip, seats: 2) }

      it 'cancels the booking' do
        booking.cancel_by_passenger!
        expect(booking.reload.status).to eq('cancelled')
      end

      it 'increments available seats' do
        expect {
          booking.cancel_by_passenger!
        }.to change { trip.reload.available_seats }.from(1).to(3)
      end
    end

    context 'when booking is pending' do
      let(:booking) { create(:booking, status: 'pending') }

      it 'cancels the booking' do
        booking.cancel_by_passenger!
        expect(booking.reload.status).to eq('cancelled')
      end

      it 'does not change available seats' do
        expect {
          booking.cancel_by_passenger!
        }.not_to change { booking.trip.reload.available_seats }
      end
    end

    context 'when booking is already cancelled' do
      let(:booking) { create(:booking, :cancelled) }

      it 'returns false' do
        expect(booking.cancel_by_passenger!).to be false
      end
    end
  end
end
