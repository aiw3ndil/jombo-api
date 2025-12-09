require 'rails_helper'

RSpec.describe 'Api::V1::Messages', type: :request do
  let(:driver) { create(:user) }
  let(:passenger) { create(:user) }
  let(:trip) { create(:trip, driver: driver) }
  let(:conversation) { trip.ensure_conversation }

  before do
    conversation.add_participant(driver)
    conversation.add_participant(passenger)
  end

  describe 'GET /api/v1/conversations/:conversation_id/messages' do
    let!(:message1) { create(:message, conversation: conversation, user: driver) }
    let!(:message2) { create(:message, conversation: conversation, user: passenger) }

    context 'when participant' do
      it 'returns all messages' do
        get "/api/v1/conversations/#{conversation.id}/messages", 
            headers: auth_headers(passenger)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.length).to eq(2)
      end

      it 'includes user information' do
        get "/api/v1/conversations/#{conversation.id}/messages", 
            headers: auth_headers(passenger)
        
        json = JSON.parse(response.body)
        expect(json.first['user']['name']).to be_present
      end
    end

    context 'when not participant' do
      let(:other_user) { create(:user) }

      it 'returns forbidden' do
        get "/api/v1/conversations/#{conversation.id}/messages", 
            headers: auth_headers(other_user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/v1/conversations/:conversation_id/messages' do
    let(:message_params) do
      {
        message: {
          content: 'Hello, this is a test message'
        }
      }
    end

    context 'when participant' do
      it 'creates a new message' do
        expect {
          post "/api/v1/conversations/#{conversation.id}/messages", 
               params: message_params, 
               headers: auth_headers(passenger)
        }.to change(Message, :count).by(1)
      end

      it 'returns created status' do
        post "/api/v1/conversations/#{conversation.id}/messages", 
             params: message_params, 
             headers: auth_headers(passenger)
        expect(response).to have_http_status(:created)
      end

      it 'associates message with current user' do
        post "/api/v1/conversations/#{conversation.id}/messages", 
             params: message_params, 
             headers: auth_headers(passenger)
        json = JSON.parse(response.body)
        expect(json['user']['id']).to eq(passenger.id)
      end
    end

    context 'with invalid content' do
      let(:invalid_params) do
        {
          message: {
            content: ''
          }
        }
      end

      it 'returns unprocessable entity' do
        post "/api/v1/conversations/#{conversation.id}/messages", 
             params: invalid_params, 
             headers: auth_headers(passenger)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when not participant' do
      let(:other_user) { create(:user) }

      it 'returns forbidden' do
        post "/api/v1/conversations/#{conversation.id}/messages", 
             params: message_params, 
             headers: auth_headers(other_user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /api/v1/conversations/:conversation_id/messages/:id' do
    let(:message) { create(:message, conversation: conversation, user: passenger) }

    context 'when message author' do
      it 'deletes the message' do
        delete "/api/v1/conversations/#{conversation.id}/messages/#{message.id}", 
               headers: auth_headers(passenger)
        
        expect(response).to have_http_status(:ok)
        expect(Message.find_by(id: message.id)).to be_nil
      end
    end

    context 'when not message author' do
      it 'returns forbidden' do
        delete "/api/v1/conversations/#{conversation.id}/messages/#{message.id}", 
               headers: auth_headers(driver)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
