require 'rails_helper'

RSpec.describe 'Api::V1::Vehicles', type: :request do
  let(:user) { create(:user) }
  let(:valid_params) do
    { vehicle: { brand: 'Volvo', model: 'V60', vehicle_type: 'estate', color: 'Black', doors: 5, seats: 5, year: 2021, fuel_type: 'diesel' } }
  end

  describe 'GET /api/v1/vehicles' do
    it 'returns only the current user vehicles' do
      own = create(:vehicle, user: user)
      other = create(:vehicle)

      get '/api/v1/vehicles', headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |v| v['id'] }
      expect(ids).to include(own.id)
      expect(ids).not_to include(other.id)
    end

    it 'requires authentication' do
      get '/api/v1/vehicles'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'POST /api/v1/vehicles' do
    it 'creates a vehicle' do
      expect {
        post '/api/v1/vehicles', params: valid_params, headers: auth_headers(user)
      }.to change(user.vehicles, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['vehicle_type']).to eq('estate')
    end

    it 'returns errors for invalid data' do
      post '/api/v1/vehicles', params: { vehicle: { brand: '' } }, headers: auth_headers(user)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['errors']).to be_present
    end
  end

  describe 'PATCH /api/v1/vehicles/:id' do
    it 'updates own vehicle' do
      vehicle = create(:vehicle, user: user)
      patch "/api/v1/vehicles/#{vehicle.id}", params: { vehicle: { color: 'Red' } }, headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      expect(vehicle.reload.color).to eq('Red')
    end

    it "cannot update another user's vehicle" do
      vehicle = create(:vehicle)
      patch "/api/v1/vehicles/#{vehicle.id}", params: { vehicle: { color: 'Red' } }, headers: auth_headers(user)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE /api/v1/vehicles/:id' do
    it 'deletes the vehicle and keeps its trips' do
      vehicle = create(:vehicle, user: user)
      trip = create(:trip, driver: user, vehicle: vehicle)

      delete "/api/v1/vehicles/#{vehicle.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(Vehicle.exists?(vehicle.id)).to be false
      expect(trip.reload.vehicle_id).to be_nil
    end
  end
end
