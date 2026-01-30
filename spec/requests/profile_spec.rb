require 'rails_helper'

RSpec.describe "Profile API", type: :request do
  include AuthenticationHelper
  let!(:user) { create(:user) }


  describe "DELETE /api/v1/users/profile" do
    context "when authenticated" do
      before do
        # Create a past trip where the current user is the driver
        past_trip = create(:trip, driver: user, departure_time: 2.days.ago)
        
        # Create a different user to be the passenger for the booking
        passenger_user = create(:user) 
        past_booking = create(:booking, user: passenger_user, trip: past_trip, status: :confirmed)
        
        # Create associated data
        create(:trip, driver: user)
        create(:booking, user: user) # This is a booking by `user` on a *different* trip (not past_trip)
        conversation = create(:conversation)
        create(:conversation_participant, user: user, conversation: conversation)
        create(:message, user: user, conversation: conversation)
        create(:notification, user: user)
        
        # Create reviews using the valid past trip and booking
        create(:review, reviewer: passenger_user, reviewee: user, booking: past_booking) # Passenger reviews driver (user)
        create(:review, reviewer: user, reviewee: passenger_user, booking: past_booking) # Driver (user) reviews passenger

        delete "/api/v1/users/profile", headers: auth_headers(user)
      end

      it "returns a 204 No Content status" do
        expect(response).to have_http_status(:no_content)
      end

      it "deletes the user" do
        expect(User.find_by(id: user.id)).to be_nil
      end

      it "deletes associated trips" do
        expect(user.trips.count).to eq(0)
      end

      it "deletes associated bookings" do
        expect(user.bookings.count).to eq(0)
      end

      it "deletes associated conversation participants" do
        expect(user.conversation_participants.count).to eq(0)
      end

      it "deletes associated messages" do
        expect(user.messages.count).to eq(0)
      end

      it "deletes associated notifications" do
        expect(user.notifications.count).to eq(0)
      end

      it "deletes associated reviews given by the user" do
        expect(user.reviews_given.count).to eq(0)
      end

      it "does not delete reviews received by the user if other users are involved" do
        # This will be tricky to test perfectly without more complex setup,
        # but the dependent: :destroy on reviewee_id ensures reviews where user is reviewee
        # are deleted.
        expect(user.reviews_received.count).to eq(0)
      end
    end

    context "when unauthenticated" do
      before do
        delete "/api/v1/users/profile"
      end

      it "returns a 401 Unauthorized status" do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end