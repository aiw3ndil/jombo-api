require 'rails_helper'

RSpec.describe 'Api::V1::Sessions', type: :request do
  describe 'POST /api/v1/login' do
    let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }

    context 'with valid credentials' do
      it 'logs in successfully' do
        post '/api/v1/login', params: {
          user: { email: 'test@example.com', password: 'password123' }
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Logged in')
        expect(response.cookies['jwt']).to be_present
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized' do
        post '/api/v1/login', params: {
          user: { email: 'test@example.com', password: 'wrongpassword' }
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with non-existent user' do
      it 'returns unauthorized' do
        post '/api/v1/login', params: {
          user: { email: 'nonexistent@example.com', password: 'password123' }
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /api/v1/logout' do
    let(:user) { create(:user) }

    it 'logs out successfully' do
      delete '/api/v1/logout', headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to eq('Logged out successfully')
    end
  end
end
