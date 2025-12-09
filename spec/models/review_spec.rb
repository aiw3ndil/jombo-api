require 'rails_helper'

RSpec.describe Review, type: :model do
  describe 'associations' do
    it { should belong_to(:booking) }
    it { should belong_to(:reviewer).class_name('User') }
    it { should belong_to(:reviewee).class_name('User') }
  end

  describe 'validations' do
    it { should validate_presence_of(:rating) }
    it { should validate_numericality_of(:rating).only_integer }
    it { should validate_numericality_of(:rating).is_greater_than_or_equal_to(1) }
    it { should validate_numericality_of(:rating).is_less_than_or_equal_to(5) }
  end

  describe 'uniqueness validation' do
    let(:driver) { create(:user) }
    let(:passenger) { create(:user) }
    let(:trip) { create(:trip, :past, driver: driver) }
    let(:booking) { create(:booking, :confirmed, user: passenger, trip: trip) }
    let!(:existing_review) { create(:review, :past_trip, booking: booking, reviewer: passenger, reviewee: driver) }

    it 'does not allow duplicate reviews per user per booking' do
      duplicate_review = build(:review, booking: booking, reviewer: passenger, reviewee: driver)
      expect(duplicate_review).not_to be_valid
      expect(duplicate_review.errors[:booking_id]).to be_present
    end
  end

  describe 'custom validations' do
    let(:driver) { create(:user) }
    let(:passenger) { create(:user) }
    let(:trip) { create(:trip, :past, driver: driver) }
    let(:booking) { create(:booking, :confirmed, user: passenger, trip: trip) }

    it 'does not allow reviewing yourself' do
      review = build(:review, :past_trip, booking: booking, reviewer: driver, reviewee: driver)
      expect(review).not_to be_valid
      expect(review.errors[:reviewee]).to include("cannot review yourself")
    end

    it 'does not allow reviewing future trips' do
      future_trip = create(:trip, driver: driver, departure_time: 2.days.from_now)
      future_booking = create(:booking, :confirmed, user: passenger, trip: future_trip)
      review = build(:review, booking: future_booking, reviewer: passenger, reviewee: driver)
      expect(review).not_to be_valid
      expect(review.errors[:base]).to include("cannot review a trip that hasn't occurred yet")
    end
  end
end
