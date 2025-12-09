require 'rails_helper'

RSpec.describe 'Api::V1::Trips', type: :request do
  let(:user) { create(:user) }
  let(:driver) { create(:user) }

  describe 'GET /api/v1/trips' do
    let!(:upcoming_trip) { create(:trip, driver: driver, departure_time: 2.days.from_now) }
    let!(:past_trip) { create(:trip, :past, driver: driver) }
    let!(:full_trip) { create(:trip, :full, driver: driver) }

    it 'returns upcoming available trips' do
      get '/api/v1/trips'
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.map { |t| t['id'] }).to include(upcoming_trip.id)
      expect(json.map { |t| t['id'] }).not_to include(past_trip.id)
    end

    it 'includes driver information' do
      get '/api/v1/trips'
      
      json = JSON.parse(response.body)
      trip = json.find { |t| t['id'] == upcoming_trip.id }
      expect(trip['driver']['name']).to eq(driver.name)
    end
  end

  describe 'GET /api/v1/trips/:id' do
    let(:trip) { create(:trip, driver: driver) }

    it 'returns trip details' do
      get "/api/v1/trips/#{trip.id}"
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(trip.id)
      expect(json['departure_location']).to eq(trip.departure_location)
    end

    context 'when trip does not exist' do
      it 'returns not found' do
        get '/api/v1/trips/99999'
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/trips' do
    let(:valid_params) do
      {
        trip: {
          departure_location: 'Madrid',
          arrival_location: 'Barcelona',
          departure_time: 2.days.from_now,
          available_seats: 3,
          price: 25.0,
          description: 'Comfortable trip'
        }
      }
    end

    context 'when authenticated' do
      it 'creates a new trip' do
        expect {
          post '/api/v1/trips', params: valid_params, headers: auth_headers(driver)
        }.to change(Trip, :count).by(1)
      end

      it 'returns created status' do
        post '/api/v1/trips', params: valid_params, headers: auth_headers(driver)
        expect(response).to have_http_status(:created)
      end

      it 'associates trip with current user' do
        post '/api/v1/trips', params: valid_params, headers: auth_headers(driver)
        json = JSON.parse(response.body)
        expect(json['driver']['id']).to eq(driver.id)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        post '/api/v1/trips', params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          trip: {
            departure_location: '',
            arrival_location: '',
            price: -10
          }
        }
      end

      it 'returns unprocessable entity' do
        post '/api/v1/trips', params: invalid_params, headers: auth_headers(driver)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT /api/v1/trips/:id' do
    let(:trip) { create(:trip, driver: driver) }
    let(:update_params) do
      {
        trip: {
          price: 30.0,
          description: 'Updated description'
        }
      }
    end

    context 'when owner' do
      it 'updates the trip' do
        put "/api/v1/trips/#{trip.id}", params: update_params, headers: auth_headers(driver)
        
        expect(response).to have_http_status(:ok)
        trip.reload
        expect(trip.price).to eq(30.0)
        expect(trip.description).to eq('Updated description')
      end
    end

    context 'when not owner' do
      it 'returns forbidden' do
        put "/api/v1/trips/#{trip.id}", params: update_params, headers: auth_headers(user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /api/v1/trips/:id' do
    let(:trip) { create(:trip, driver: driver) }

    context 'when owner' do
      it 'deletes the trip' do
        delete "/api/v1/trips/#{trip.id}", headers: auth_headers(driver)
        expect(response).to have_http_status(:ok)
        expect(Trip.find_by(id: trip.id)).to be_nil
      end
    end

    context 'when not owner' do
      it 'returns forbidden' do
        delete "/api/v1/trips/#{trip.id}", headers: auth_headers(user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
