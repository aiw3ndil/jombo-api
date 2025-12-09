require 'rails_helper'

RSpec.describe 'Api::V1::Reviews', type: :request do
  let(:driver) { create(:user) }
  let(:passenger) { create(:user) }
  let(:trip) { create(:trip, :past, driver: driver) }
  let(:booking) { create(:booking, :confirmed, trip: trip, user: passenger) }

  describe 'POST /api/v1/bookings/:booking_id/reviews' do
    let(:review_params) do
      {
        review: {
          rating: 5,
          comment: 'Great trip!',
          reviewee_id: driver.id
        }
      }
    end

    context 'when authenticated' do
      it 'creates a new review' do
        expect {
          post "/api/v1/bookings/#{booking.id}/reviews", 
               params: review_params, 
               headers: auth_headers(passenger)
        }.to change(Review, :count).by(1)
      end

      it 'returns created status' do
        post "/api/v1/bookings/#{booking.id}/reviews", 
             params: review_params, 
             headers: auth_headers(passenger)
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid rating' do
      let(:invalid_params) do
        {
          review: {
            rating: 10,
            comment: 'Invalid rating',
            reviewee_id: driver.id
          }
        }
      end

      it 'returns unprocessable entity' do
        post "/api/v1/bookings/#{booking.id}/reviews", 
             params: invalid_params, 
             headers: auth_headers(passenger)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /api/v1/users/:user_id/reviews' do
    let!(:review1) { create(:review, :past_trip, reviewee: driver, rating: 5) }
    let(:other_user) { create(:user) }
    let!(:review2) { create(:review, :past_trip, reviewee: other_user, rating: 3) }

    it 'returns reviews for specific user' do
      get "/api/v1/users/#{driver.id}/reviews"
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.map { |r| r['id'] }).to include(review1.id)
      expect(json.map { |r| r['id'] }).not_to include(review2.id)
    end
  end
end
