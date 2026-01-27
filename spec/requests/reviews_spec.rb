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
    let(:reviewer_for_1) { create(:user) }
    let(:trip1) { create(:trip, :past, driver: driver) }
    let(:booking1) { create(:booking, :confirmed, trip: trip1, user: reviewer_for_1) }
    
    let!(:review1) do
      create(:review,
        booking: booking1,
        reviewer: reviewer_for_1,
        reviewee: driver,
        rating: 5
      )    
    end
    
    let!(:other_user) { create(:user) }
    let(:reviewer_for_2) { create(:user) }
    let(:trip2) { create(:trip, :past, driver: other_user) }
    let(:booking2) { create(:booking, :confirmed, trip: trip2, user: reviewer_for_2) } 
    
    let!(:review2) do
      create(:review,
      booking: booking2,
      reviewer: reviewer_for_2,
      reviewee: other_user,
      rating: 3
      )
    end

    it 'returns reviews for specific user' do
      get "/api/v1/users/#{driver.id}/reviews"
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.map { |r| r['id'] }).to include(review1.id)
      expect(json.map { |r| r['id'] }).not_to include(review2.id)
    end
  end
end
