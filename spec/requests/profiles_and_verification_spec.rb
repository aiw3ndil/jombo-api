require 'rails_helper'

RSpec.describe 'Public profiles and verification', type: :request do
  let(:user) { create(:user, :unverified, bio: 'Commuting Tampere–Helsinki every week', phone: '0401234567') }

  before { SmsService.deliveries.clear }

  describe 'GET /api/v1/users/:id' do
    it 'returns the public profile without private data' do
      create(:trip, driver: user, departure_time: 3.days.from_now)
      get "/api/v1/users/#{user.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to include('name' => user.name, 'bio' => user.bio, 'experience_level' => 'new')
      expect(json['verifications']).to eq('email' => false, 'phone' => false, 'google' => false, 'verified' => false)
      expect(json['upcoming_trips'].size).to eq(1)
      expect(json.keys).not_to include('email', 'phone')
      expect(response.body).not_to include(user.email)
      expect(response.body).not_to include('+358401234567')
    end

    it 'returns 404 for an unknown user' do
      get '/api/v1/users/0'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'experience level' do
    it 'grows with completed trips and good ratings' do
      3.times do
        trip = create(:trip, driver: user, departure_time: 2.days.from_now)
        trip.update_column(:departure_time, 2.days.ago)
        booking = create(:booking, trip: trip, status: 'confirmed')
        Review.create!(booking: booking, reviewer: booking.user, reviewee: user, rating: 5)
      end
      expect(user.completed_trips_count).to eq(3)
      expect(user.experience_level).to eq('regular')
    end

    it 'also counts rides taken as a passenger' do
      3.times do
        trip = create(:trip, departure_time: 2.days.from_now)
        trip.update_column(:departure_time, 2.days.ago)
        booking = create(:booking, trip: trip, user: user, status: 'confirmed')
        Review.create!(booking: booking, reviewer: trip.driver, reviewee: user, rating: 5)
      end
      expect(user.rides_taken_count).to eq(3)
      expect(user.experience_level).to eq('regular')
    end
  end

  describe 'verified member' do
    it 'requires email and phone while SMS is available' do
      user.verify_email!
      expect(user.verified_member?).to be(false)
      user.update_column(:phone_verified_at, Time.current)
      expect(user.reload.verifications).to include(verified: true)
    end

    it 'only requires email when SMS is unavailable' do
      allow(SmsService).to receive(:enabled?).and_return(false)
      user.verify_email!
      expect(user.verified_member?).to be(true)
      expect(user.can_publish_trips?).to be(true)
    end
  end

  describe 'email verification' do
    it 'sends the email on registration and confirms with the token' do
      expect {
        post '/api/v1/register', params: { user: { email: 'new@example.com', password: 'secret123', name: 'New' } }
      }.to have_enqueued_mail(UserMailer, :email_verification)

      new_user = User.find_by(email: 'new@example.com')
      post '/api/v1/verification/email/confirm', params: { token: new_user.email_verification_token }
      expect(response).to have_http_status(:ok)
      expect(new_user.reload.email_verified?).to be(true)
    end

    it 'rejects an invalid token' do
      post '/api/v1/verification/email/confirm', params: { token: 'nope' }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'clears verification when the email changes' do
      user.verify_email!
      user.update!(email: 'changed@example.com')
      expect(user.reload.email_verified?).to be(false)
    end
  end

  describe 'phone verification' do
    it 'normalises Finnish numbers' do
      expect(user.phone).to eq('+358401234567')
    end

    it 'sends a code by SMS and verifies it' do
      post '/api/v1/verification/phone', headers: auth_headers(user)
      expect(response).to have_http_status(:ok)
      code = SmsService.deliveries.last[:body][/\d{6}/]

      post '/api/v1/verification/phone/confirm', headers: auth_headers(user), params: { code: '000000' == code ? '111111' : '000000' }
      expect(response).to have_http_status(:unprocessable_entity)

      post '/api/v1/verification/phone/confirm', headers: auth_headers(user), params: { code: code }
      expect(response).to have_http_status(:ok)
      expect(user.reload.phone_verified?).to be(true)
    end

    it 'rate-limits new codes' do
      post '/api/v1/verification/phone', headers: auth_headers(user)
      post '/api/v1/verification/phone', headers: auth_headers(user)
      expect(response).to have_http_status(:too_many_requests)
    end

    it 'resets verification when the phone changes' do
      user.update_column(:phone_verified_at, Time.current)
      user.update!(phone: '+358409999999')
      expect(user.reload.phone_verified?).to be(false)
    end
  end
end
