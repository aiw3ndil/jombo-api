require 'rails_helper'

RSpec.describe 'Trip search filters, stops and instant booking', type: :request do
  let(:driver) { create(:user) }
  let(:passenger) { create(:user) }
  let(:tomorrow) { Time.find_zone('Europe/Helsinki').now.tomorrow.change(hour: 9) }

  let!(:with_stops) do
    build(:trip, driver: driver, departure_location: 'Helsinki', arrival_location: 'Oulu',
                 departure_time: tomorrow, price: 40, pets_allowed: true).tap do |t|
      t.assign_stops([{ location: 'Tampere', departure_time: tomorrow + 2.hours, price_from_origin: 12 }])
      t.save!
    end
  end
  let!(:direct) do
    create(:trip, departure_location: 'Tampere', arrival_location: 'Oulu',
                  departure_time: tomorrow.change(hour: 19), price: 20, instant_booking: true)
  end

  def search(params)
    get '/api/v1/trips/search', params: params
    JSON.parse(response.body)['trips']
  end

  it 'finds trips passing through an intermediate stop with the segment price' do
    trips = search(departure_location: 'Tampere', arrival_location: 'Oulu')
    found = trips.find { |t| t['id'] == with_stops.id }
    expect(found['segment']).to include('from' => 'Tampere', 'to' => 'Oulu', 'price' => 28.0)
    expect(found['stops'].map { |s| s['location'] }).to eq(['Tampere'])
    expect(trips.map { |t| t['id'] }).to include(direct.id)
  end

  it 'does not match places in the wrong order' do
    expect(search(departure_location: 'Oulu', arrival_location: 'Tampere')).to be_empty
  end

  it 'sorts by segment price' do
    ids = search(departure_location: 'Tampere', arrival_location: 'Oulu', sort: 'price').map { |t| t['id'] }
    expect(ids).to eq([direct.id, with_stops.id])
  end

  it 'filters by preferences and time of day' do
    expect(search(departure_location: 'Tampere', arrival_location: 'Oulu', pets: 'true').map { |t| t['id'] }).to eq([with_stops.id])
    expect(search(departure_location: 'Tampere', arrival_location: 'Oulu', instant_booking: 'true').map { |t| t['id'] }).to eq([direct.id])
    expect(search(departure_location: 'Tampere', arrival_location: 'Oulu', time_of_day: 'evening').map { |t| t['id'] }).to eq([direct.id])
  end

  it 'filters by date and max price' do
    date = tomorrow.to_date.iso8601
    expect(search(departure_location: 'Tampere', arrival_location: 'Oulu', date: date).size).to eq(2)
    expect(search(departure_location: 'Tampere', arrival_location: 'Oulu', date: (tomorrow + 2.days).to_date.iso8601)).to be_empty
    expect(search(departure_location: 'Tampere', arrival_location: 'Oulu', max_price: 25).map { |t| t['id'] }).to eq([direct.id])
  end

  it 'does not expose the driver email' do
    trips = search(departure_location: 'Helsinki', arrival_location: 'Oulu')
    expect(trips.first['driver'].keys).not_to include('email', 'phone')
  end

  it 'includes the driver experience level and verifications' do
    driver_json = search(departure_location: 'Helsinki', arrival_location: 'Oulu').first['driver']
    expect(driver_json['experience_level']).to eq('new')
    expect(driver_json['verifications']).to include('email' => true, 'phone' => true, 'verified' => true)
  end

  it 'filters to verified drivers only' do
    direct.driver.update_column(:phone_verified_at, nil)
    ids = search(departure_location: 'Tampere', arrival_location: 'Oulu', verified: true).map { |t| t['id'] }
    expect(ids).to eq([with_stops.id])
  end

  it 'creates and replaces stops through the API' do
    post '/api/v1/trips', headers: auth_headers(driver), params: {
      trip: { departure_location: 'Turku', arrival_location: 'Tampere', departure_time: tomorrow.iso8601,
              available_seats: 2, price: 15, vehicle_id: with_stops.vehicle_id, chattiness: 'quiet',
              stops: [{ location: 'Forssa', departure_time: (tomorrow + 1.hour).iso8601, price_from_origin: 7 }] }
    }
    expect(response).to have_http_status(:created)
    json = JSON.parse(response.body)
    expect(json['stops'].map { |s| s['location'] }).to eq(['Forssa'])
    expect(json['chattiness']).to eq('quiet')

    patch "/api/v1/trips/#{json['id']}", headers: auth_headers(driver), params: { trip: { stops: '' } }
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)['stops']).to eq([])
  end

  describe 'booking' do
    it 'stores the booked segment and its price' do
      post "/api/v1/trips/#{with_stops.id}/bookings", headers: auth_headers(passenger),
           params: { booking: { seats: 1, pickup_location: 'Tampere', dropoff_location: 'Oulu' } }
      expect(response).to have_http_status(:created)
      booking = Booking.last
      expect([booking.pickup_location, booking.dropoff_location, booking.price_per_seat.to_f]).to eq(['Tampere', 'Oulu', 28.0])
      expect(booking.status).to eq('pending')
    end

    it 'rejects a segment the trip does not serve' do
      post "/api/v1/trips/#{with_stops.id}/bookings", headers: auth_headers(passenger),
           params: { booking: { seats: 1, pickup_location: 'Turku' } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'confirms instantly when the trip has instant booking' do
      expect {
        post "/api/v1/trips/#{direct.id}/bookings", headers: auth_headers(passenger), params: { booking: { seats: 2 } }
      }.to have_enqueued_mail(UserMailer, :booking_confirmed)
      expect(JSON.parse(response.body)['status']).to eq('confirmed')
      expect(direct.reload.available_seats).to eq(1)
      expect(Notification.where(user: direct.driver).count).to eq(1)
    end
  end
end
