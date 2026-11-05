require 'rails_helper'

RSpec.describe 'Trust and safety', type: :request do
  let(:driver) { create(:user) }
  let(:passenger) { create(:user) }
  let(:trip) { create(:trip, driver: driver, departure_location: 'Helsinki', arrival_location: 'Tampere', available_seats: 3) }

  def json
    JSON.parse(response.body)
  end

  describe 'driver cancels a trip' do
    it 'cancels a trip with bookings and notifies the passengers' do
      booking = create(:booking, trip: trip, user: passenger, seats: 1)
      booking.confirm_by_driver!
      pending_booking = create(:booking, trip: trip, user: create(:user))

      expect {
        delete "/api/v1/trips/#{trip.id}", headers: auth_headers(driver)
      }.to have_enqueued_mail(UserMailer, :trip_cancelled).twice

      expect(response).to have_http_status(:ok)
      expect(json['cancelled']).to eq(1)
      expect(trip.reload.cancelled_at).to be_present
      expect(booking.reload).to have_attributes(status: 'cancelled', cancelled_by: 'driver')
      expect(pending_booking.reload.cancelled_by).to eq('driver')
    end

    it 'deletes a trip without bookings' do
      delete "/api/v1/trips/#{trip.id}", headers: auth_headers(driver)
      expect(Trip.exists?(trip.id)).to be(false)
    end

    it 'hides cancelled trips from search, my trips and booking' do
      create(:booking, trip: trip, user: passenger)
      trip.cancel_by_driver!

      get '/api/v1/trips/search', params: { departure_location: 'Helsinki', arrival_location: 'Tampere' }
      expect(json['trips']).to be_empty

      get '/api/v1/trips/my_trips', headers: auth_headers(driver)
      expect(json).to be_empty

      post "/api/v1/trips/#{trip.id}/bookings", params: { booking: { seats: 1 } }, headers: auth_headers(create(:user))
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'reliability' do
    it 'is nil with fewer than 3 data points' do
      expect(driver.reliability).to eq(cancellation_rate: nil, response_hours: nil)
    end

    it 'computes the cancellation rate and the median response time' do
      bookings = Array.new(4) { create(:booking, trip: create(:trip, driver: driver), user: create(:user)) }
      bookings.each_with_index do |b, i|
        b.update_column(:created_at, (i + 1).hours.ago)
        b.confirm_by_driver!
      end
      bookings.first.cancel!(by: 'driver')

      expect(driver.driver_cancellation_rate).to eq(25)
      expect(driver.median_response_hours).to be_within(0.1).of(2.5)

      get "/api/v1/users/#{driver.id}"
      expect(json['reliability']).to include('cancellation_rate' => 25)
    end
  end

  describe 'reports' do
    it 'stores the report and emails the admin' do
      expect {
        post '/api/v1/reports', params: { reported_id: driver.id, reason: 'no_show', comment: 'Never came' },
                                headers: auth_headers(passenger)
      }.to have_enqueued_mail(AdminMailer, :new_report)
      expect(response).to have_http_status(:created)
      expect(Report.last).to have_attributes(reporter_id: passenger.id, reported_id: driver.id, reason: 'no_show')
    end

    it 'allows one report per user per day' do
      2.times { post '/api/v1/reports', params: { reported_id: driver.id, reason: 'other' }, headers: auth_headers(passenger) }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'rejects reporting yourself and invalid reasons' do
      post '/api/v1/reports', params: { reported_id: passenger.id, reason: 'other' }, headers: auth_headers(passenger)
      expect(response).to have_http_status(:unprocessable_entity)
      post '/api/v1/reports', params: { reported_id: driver.id, reason: 'nope' }, headers: auth_headers(passenger)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'only accepts a booking both users shared' do
      other_booking = create(:booking, user: create(:user))
      post '/api/v1/reports', params: { reported_id: driver.id, reason: 'other', booking_id: other_booking.id },
                              headers: auth_headers(passenger)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'renders the admin email with the details' do
      ENV['ADMIN_EMAIL'] = 'admin@example.com'
      report = Report.create!(reporter: passenger, reported: driver, reason: 'unsafe_driving', comment: 'Too fast')
      mail = AdminMailer.new_report(report)
      expect(mail.to).to eq(['admin@example.com'])
      expect(mail.body.to_s).to include('unsafe_driving', 'Too fast', driver.name)
    ensure
      ENV.delete('ADMIN_EMAIL')
    end
  end

  describe 'blocks' do
    before { post "/api/v1/users/#{driver.id}/block", headers: auth_headers(passenger) }

    it 'blocks and unblocks a user' do
      expect(response).to have_http_status(:created)
      expect(passenger.blocked_with?(driver)).to be(true)
      expect(driver.blocked_with?(passenger)).to be(true)

      get "/api/v1/users/#{driver.id}", headers: auth_headers(passenger)
      expect(json['blocked']).to be(true)

      delete "/api/v1/users/#{driver.id}/block", headers: auth_headers(passenger)
      expect(passenger.blocked_with?(driver)).to be(false)
    end

    it 'prevents booking in both directions' do
      post "/api/v1/trips/#{trip.id}/bookings", params: { booking: { seats: 1 } }, headers: auth_headers(passenger)
      expect(response).to have_http_status(:forbidden)
      expect(json['error_code']).to eq('blocked')

      passenger_trip = create(:trip, driver: passenger)
      post "/api/v1/trips/#{passenger_trip.id}/bookings", params: { booking: { seats: 1 } }, headers: auth_headers(driver)
      expect(response).to have_http_status(:forbidden)
    end

    it 'hides the blocked user trips from search' do
      trip
      get '/api/v1/trips/search', params: { departure_location: 'Helsinki', arrival_location: 'Tampere' },
                                  headers: auth_headers(passenger)
      expect(json['trips']).to be_empty

      get '/api/v1/trips/search', params: { departure_location: 'Helsinki', arrival_location: 'Tampere' }
      expect(json['trips'].size).to eq(1)
    end

    it 'prevents sending messages' do
      delete "/api/v1/users/#{driver.id}/block", headers: auth_headers(passenger)
      booking = create(:booking, trip: trip, user: passenger)
      booking.confirm_by_driver!
      conversation = trip.reload.conversation
      post "/api/v1/users/#{driver.id}/block", headers: auth_headers(passenger)

      post "/api/v1/conversations/#{conversation.id}/messages", params: { message: { content: 'Hi' } },
                                                                headers: auth_headers(driver)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'privacy' do
    it 'does not expose emails in conversations and messages' do
      booking = create(:booking, trip: trip, user: passenger)
      booking.confirm_by_driver!
      conversation = trip.reload.conversation

      post "/api/v1/conversations/#{conversation.id}/messages", params: { message: { content: 'Hi' } },
                                                                headers: auth_headers(passenger)
      expect(response).to have_http_status(:created)
      get "/api/v1/conversations/#{conversation.id}", headers: auth_headers(driver)
      get '/api/v1/conversations', headers: auth_headers(driver)
      [passenger.email, driver.email].each { |email| expect(response.body).not_to include(email) }
    end
  end
end
