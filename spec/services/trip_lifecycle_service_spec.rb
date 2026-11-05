require 'rails_helper'

RSpec.describe TripLifecycleService do
  let(:driver) { create(:user) }
  let(:passenger) { create(:user) }
  let(:mails) { ActionMailer::Base.deliveries }

  before { mails.clear }

  def trip_departing(time, **attrs)
    create(:trip, driver: driver, **attrs).tap { |t| t.update_column(:departure_time, time) }
  end

  def subjects_for(user)
    mails.select { |m| m.to == [user.email] }.map(&:subject)
  end

  describe 'reminders' do
    it 'reminds passengers and the driver once, within 24 hours of departure' do
      trip = trip_departing(20.hours.from_now)
      booking = create(:booking, :confirmed, trip: trip, user: passenger)
      create(:booking, :confirmed, trip: trip_departing(3.days.from_now), user: create(:user))

      result = described_class.run
      expect(result[:reminders]).to eq(2)
      expect(subjects_for(passenger)).to contain_exactly(a_string_including('is coming up'))
      expect(subjects_for(driver)).to contain_exactly(a_string_including('is coming up'))
      expect(booking.reload.reminder_sent_at).to be_present

      mails.clear
      expect(described_class.run[:reminders]).to eq(0)
      expect(mails).to be_empty
    end

    it 'does not remind the driver of a trip without confirmed passengers' do
      trip = trip_departing(5.hours.from_now)
      create(:booking, trip: trip, user: passenger, created_at: 1.hour.ago)
      described_class.run
      expect(subjects_for(driver)).to be_empty
    end
  end

  describe 'expiring pending requests' do
    it 'expires requests older than 48 hours and notifies the passenger' do
      booking = create(:booking, trip: trip_departing(5.days.from_now), user: passenger)
      booking.update_column(:created_at, 49.hours.ago)

      expect(described_class.run[:expired]).to eq(1)
      expect(booking.reload).to have_attributes(status: 'expired', cancelled_by: 'system')
      expect(subjects_for(passenger)).to contain_exactly(a_string_including('has expired'))
    end

    it 'expires requests for trips leaving within 2 hours' do
      booking = create(:booking, trip: trip_departing(90.minutes.from_now), user: passenger)
      described_class.run
      expect(booking.reload.status).to eq('expired')
    end

    it 'expires requests for past trips without emailing' do
      booking = create(:booking, trip: trip_departing(2.days.ago), user: passenger)
      described_class.run
      expect(booking.reload.status).to eq('expired')
      expect(mails).to be_empty
    end

    it 'leaves recent requests alone' do
      booking = create(:booking, trip: trip_departing(3.days.from_now), user: passenger)
      described_class.run
      expect(booking.reload.status).to eq('pending')
    end
  end

  describe 'review requests' do
    it 'asks passenger and driver for a review after the trip, once' do
      trip = trip_departing(5.hours.ago, duration_minutes: 120)
      booking = create(:booking, :confirmed, trip: trip, user: passenger)

      expect(described_class.run[:review_requests]).to eq(1)
      expect(subjects_for(passenger)).to contain_exactly(a_string_including('How was your ride'))
      expect(subjects_for(driver)).to contain_exactly(a_string_including('How was your ride'))
      expect(booking.reload.review_requested_at).to be_present

      mails.clear
      described_class.run
      expect(mails).to be_empty
    end

    it 'waits until the trip has finished' do
      trip = trip_departing(1.hour.ago, duration_minutes: 120)
      create(:booking, :confirmed, trip: trip, user: passenger)
      expect(described_class.run[:review_requests]).to eq(0)
    end

    it 'ignores old trips' do
      create(:booking, :confirmed, trip: trip_departing(10.days.ago), user: passenger)
      expect(described_class.run[:review_requests]).to eq(0)
    end
  end

  it 'renders every email in Finnish' do
    fi_driver = create(:user, :finnish)
    fi_passenger = create(:user, :finnish)
    soon = create(:trip, driver: fi_driver).tap { |t| t.update_column(:departure_time, 10.hours.from_now) }
    create(:booking, :confirmed, trip: soon, user: fi_passenger)
    stale = create(:booking, trip: create(:trip, driver: fi_driver, departure_time: 4.days.from_now), user: fi_passenger)
    stale.update_column(:created_at, 3.days.ago)
    past = create(:trip, driver: fi_driver).tap { |t| t.update_column(:departure_time, 6.hours.ago) }
    create(:booking, :confirmed, trip: past, user: fi_passenger)

    described_class.run
    expect(mails.size).to eq(5)
    mails.each do |mail|
      expect(mail.html_part.body.to_s).not_to include('translation missing')
      expect(mail.text_part.body.to_s).not_to include('translation missing')
    end
    expect(mails.map(&:subject)).to include(a_string_including('lähestyy'), a_string_including('vanheni'), a_string_including('sujui'))
  end

  it 'records who answered and who cancelled bookings' do
    booking = create(:booking, trip: trip_departing(3.days.from_now), user: passenger)
    booking.confirm_by_driver!
    expect(booking.reload.responded_at).to be_present
    booking.cancel_by_passenger!
    expect(booking.reload).to have_attributes(status: 'cancelled', cancelled_by: 'passenger')
  end
end
