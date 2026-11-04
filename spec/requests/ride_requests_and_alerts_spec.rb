require 'rails_helper'

RSpec.describe 'Ride requests, search alerts and matching', type: :request do
  include ActiveJob::TestHelper

  let(:passenger) { create(:user) }
  let(:driver) { create(:user) }
  let(:date) { 3.days.from_now.to_date }

  describe 'ride requests' do
    it 'creates a request and lists it publicly without the email' do
      post '/api/v1/ride_requests', headers: auth_headers(passenger), params: {
        ride_request: { departure_location: 'Helsinki', arrival_location: 'Kuopio', departure_date: date, seats: 2, flexible_days: 1 }
      }
      expect(response).to have_http_status(:created)

      get '/api/v1/ride_requests', params: { from: 'helsinki' }
      json = JSON.parse(response.body)
      expect(json.size).to eq(1)
      expect(json.first['user']['name']).to eq(passenger.name)
      expect(response.body).not_to include(passenger.email)
    end

    it 'rejects past dates and lets only the owner delete' do
      post '/api/v1/ride_requests', headers: auth_headers(passenger), params: {
        ride_request: { departure_location: 'A', arrival_location: 'B', departure_date: Date.yesterday }
      }
      expect(response).to have_http_status(:unprocessable_entity)

      request = RideRequest.create!(user: passenger, departure_location: 'A', arrival_location: 'B', departure_date: date)
      delete "/api/v1/ride_requests/#{request.id}", headers: auth_headers(driver)
      expect(response).to have_http_status(:not_found)
      delete "/api/v1/ride_requests/#{request.id}", headers: auth_headers(passenger)
      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'search alerts' do
    it 'creates, lists and deletes alerts' do
      post '/api/v1/search_alerts', headers: auth_headers(passenger),
           params: { search_alert: { departure_location: 'Turku', arrival_location: 'Tampere' } }
      expect(response).to have_http_status(:created)

      post '/api/v1/search_alerts', headers: auth_headers(passenger),
           params: { search_alert: { departure_location: 'Turku', arrival_location: 'Tampere' } }
      expect(response).to have_http_status(:unprocessable_entity)

      get '/api/v1/search_alerts', headers: auth_headers(passenger)
      id = JSON.parse(response.body).first['id']
      delete "/api/v1/search_alerts/#{id}", headers: auth_headers(passenger)
      expect(response).to have_http_status(:no_content)
    end

    it 'requires authentication' do
      get '/api/v1/search_alerts'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe TripMatchJob do
    let!(:alert) { SearchAlert.create!(user: passenger, departure_location: 'Tampere', arrival_location: 'Oulu') }
    let(:other) { create(:user) }
    let!(:ride_request) do
      RideRequest.create!(user: other, departure_location: 'Helsinki', arrival_location: 'Oulu',
                          departure_date: date, flexible_days: 1)
    end

    def publish(**attrs)
      build(:trip, driver: driver, departure_location: 'Helsinki', arrival_location: 'Oulu',
                   departure_time: date.in_time_zone('Europe/Helsinki').change(hour: 8), price: 40, **attrs).tap do |t|
        t.assign_stops([{ location: 'Tampere', departure_time: t.departure_time + 2.hours, price_from_origin: 12 }])
        t.save!
      end
    end

    it 'is enqueued when a trip is published' do
      expect { publish }.to have_enqueued_job(TripMatchJob)
    end

    it 'emails users whose alert or request matches, including via stops' do
      trip = publish
      expect {
        TripMatchJob.perform_now(trip.id)
      }.to have_enqueued_mail(UserMailer, :trip_match).twice
      expect(alert.reload.last_notified_at).to be_present
    end

    it 'does not notify the driver or non-matching routes' do
      SearchAlert.create!(user: driver, departure_location: 'Helsinki', arrival_location: 'Oulu')
      SearchAlert.create!(user: create(:user), departure_location: 'Oulu', arrival_location: 'Tampere')
      trip = publish
      expect { TripMatchJob.perform_now(trip.id) }.to have_enqueued_mail(UserMailer, :trip_match).twice
    end

    it 'creates the in-app notification when the email is delivered' do
      trip = publish
      perform_enqueued_jobs { TripMatchJob.perform_now(trip.id) }
      expect(Notification.where(user: passenger, notification_type: 'trip').count).to eq(1)
    end

    it 'sends an offer email for the request the driver replied to' do
      trip = publish
      expect {
        TripMatchJob.perform_now(trip.id, ride_request.id)
      }.to have_enqueued_mail(UserMailer, :trip_match).with(other, trip, 'Helsinki', 'Oulu', offer: true)
    end
  end
end
