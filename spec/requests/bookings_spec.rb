require 'rails_helper'

RSpec.describe 'Api::V1::Bookings', type: :request do
  let(:user) { create(:user) }
  let(:driver) { create(:user) }
  let(:trip) { create(:trip, driver: driver, available_seats: 3) }

  describe 'POST /api/v1/trips/:trip_id/bookings' do
    let(:valid_params) do
      {
        booking: {
          seats: 2
        }
      }
    end

    context 'when authenticated' do
      it 'creates a new booking' do
        expect {
          post "/api/v1/trips/#{trip.id}/bookings", 
               params: valid_params, 
               headers: auth_headers(user)
        }.to change(Booking, :count).by(1)
      end

      it 'returns created status' do
        post "/api/v1/trips/#{trip.id}/bookings", 
             params: valid_params, 
             headers: auth_headers(user)
        expect(response).to have_http_status(:created)
      end

      it 'sets status to pending' do
        post "/api/v1/trips/#{trip.id}/bookings", 
             params: valid_params, 
             headers: auth_headers(user)
        json = JSON.parse(response.body)
        expect(json['status']).to eq('pending')
      end
    end

    context 'when driver tries to book own trip' do
      it 'returns unprocessable entity' do
        post "/api/v1/trips/#{trip.id}/bookings", 
             params: valid_params, 
             headers: auth_headers(driver)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with invalid seats' do
      let(:invalid_params) do
        {
          booking: {
            seats: 10
          }
        }
      end

      it 'returns unprocessable entity' do
        post "/api/v1/trips/#{trip.id}/bookings", 
             params: invalid_params, 
             headers: auth_headers(user)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        post "/api/v1/trips/#{trip.id}/bookings", params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PUT /api/v1/trips/:trip_id/bookings/:id/confirm' do
    let(:booking) { create(:booking, trip: trip, user: user, seats: 2) }

    context 'when driver' do
      it 'confirms the booking and sends a confirmation email' do
        expect {
          put "/api/v1/trips/#{trip.id}/bookings/#{booking.id}/confirm",
              headers: auth_headers(driver)
        }.to have_enqueued_mail(UserMailer, :booking_confirmed).with(user, booking)

        expect(response).to have_http_status(:ok)
        booking.reload
        expect(booking.status).to eq('confirmed')
      end

      it 'decrements available seats' do
        expect {
          put "/api/v1/trips/#{trip.id}/bookings/#{booking.id}/confirm",
              headers: auth_headers(driver)
          trip.reload
        }.to change { trip.available_seats }.from(3).to(1)
      end
    end

    context 'when not driver' do
      it 'returns forbidden' do
        put "/api/v1/trips/#{trip.id}/bookings/#{booking.id}/confirm",
            headers: auth_headers(user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'PUT /api/v1/trips/:trip_id/bookings/:id/reject' do
    let(:booking) { create(:booking, trip: trip, user: user) }

    context 'when driver' do
      it 'rejects the booking and sends a rejection email' do
        expect {
          put "/api/v1/trips/#{trip.id}/bookings/#{booking.id}/reject",
              headers: auth_headers(driver)
        }.to have_enqueued_mail(UserMailer, :booking_rejected).with(user, booking)

        expect(response).to have_http_status(:ok)
        booking.reload
        expect(booking.status).to eq('rejected')
      end
    end

    context 'when not driver' do
      it 'returns forbidden' do
        put "/api/v1/trips/#{trip.id}/bookings/#{booking.id}/reject",
            headers: auth_headers(user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /api/v1/bookings/:id' do
    let(:booking) { create(:booking, :confirmed, trip: trip, user: user, seats: 2) }

    context 'when booking owner' do
      it 'cancels the booking' do
        delete "/api/v1/bookings/#{booking.id}", headers: auth_headers(user)
        
        expect(response).to have_http_status(:ok)
        booking.reload
        expect(booking.status).to eq('cancelled')
      end

      it 'increments available seats' do
        expect {
          delete "/api/v1/bookings/#{booking.id}", headers: auth_headers(user)
          trip.reload
        }.to change { trip.available_seats }.from(3).to(5)
      end
    end

    context 'when not booking owner' do
      let(:other_user) { create(:user) }

      it 'returns forbidden' do
        delete "/api/v1/bookings/#{booking.id}", headers: auth_headers(other_user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
