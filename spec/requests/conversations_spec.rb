require 'rails_helper'

RSpec.describe 'Api::V1::Conversations', type: :request do
  let(:driver) { create(:user) }
  let(:passenger) { create(:user) }
  let(:trip) { create(:trip, driver: driver) }
  let(:booking) { create(:booking, :confirmed, trip: trip, user: passenger) }
  let(:conversation) { trip.ensure_conversation }

  before do
    conversation.add_participant(driver)
    conversation.add_participant(passenger)
  end

  describe 'GET /api/v1/conversations' do
    context 'when authenticated' do
      it 'returns user conversations' do
        get '/api/v1/conversations', headers: auth_headers(passenger)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.map { |c| c['id'] }).to include(conversation.id)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get '/api/v1/conversations'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/conversations/:id' do
    let!(:message) { create(:message, conversation: conversation, user: driver) }

    context 'when participant' do
      it 'returns conversation with messages' do
        get "/api/v1/conversations/#{conversation.id}", headers: auth_headers(passenger)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['conversation']['id']).to eq(conversation.id)
        expect(json['messages'].length).to eq(1)
      end
    end

    context 'when not participant' do
      let(:other_user) { create(:user) }

      it 'returns forbidden' do
        get "/api/v1/conversations/#{conversation.id}", headers: auth_headers(other_user)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /api/v1/conversations/:id' do
    context 'when driver' do
      it 'deletes the conversation' do
        delete "/api/v1/conversations/#{conversation.id}", headers: auth_headers(driver)
        
        expect(response).to have_http_status(:ok)
        expect(Conversation.find_by(id: conversation.id)).to be_nil
      end
    end

    context 'when not driver' do
      it 'returns forbidden' do
        delete "/api/v1/conversations/#{conversation.id}", headers: auth_headers(passenger)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
