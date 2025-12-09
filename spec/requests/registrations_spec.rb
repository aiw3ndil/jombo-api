require 'rails_helper'

RSpec.describe 'Api::V1::Registrations', type: :request do
  describe 'POST /api/v1/register' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            name: 'New User',
            language: 'en'
          }
        }
      end

      it 'creates a new user' do
        expect {
          post '/api/v1/register', params: valid_params
        }.to change(User, :count).by(1)
      end

      it 'returns created status' do
        post '/api/v1/register', params: valid_params
        expect(response).to have_http_status(:created)
      end

      it 'returns user data' do
        post '/api/v1/register', params: valid_params
        json = JSON.parse(response.body)
        expect(json['user']['email']).to eq('newuser@example.com')
        expect(json['user']['name']).to eq('New User')
      end

      it 'sets JWT cookie' do
        post '/api/v1/register', params: valid_params
        expect(response.cookies['jwt']).to be_present
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          user: {
            email: '',
            password: 'short',
            name: ''
          }
        }
      end

      it 'does not create a user' do
        expect {
          post '/api/v1/register', params: invalid_params
        }.not_to change(User, :count)
      end

      it 'returns unprocessable entity status' do
        post '/api/v1/register', params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error messages' do
        post '/api/v1/register', params: invalid_params
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end

    context 'with duplicate email' do
      let!(:existing_user) { create(:user, email: 'existing@example.com') }
      let(:duplicate_params) do
        {
          user: {
            email: 'existing@example.com',
            password: 'password123',
            name: 'Duplicate User'
          }
        }
      end

      it 'does not create a user' do
        expect {
          post '/api/v1/register', params: duplicate_params
        }.not_to change(User, :count)
      end

      it 'returns error message' do
        post '/api/v1/register', params: duplicate_params
        json = JSON.parse(response.body)
        expect(json['errors']).to include(/email/i)
      end
    end
  end
end
