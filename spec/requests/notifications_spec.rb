require 'rails_helper'

RSpec.describe 'Api::V1::Notifications', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'GET /api/v1/notifications' do
    let!(:notification1) { create(:notification, user: user, read: false, created_at: 2.hours.ago) }
    let!(:notification2) { create(:notification, user: user, read: true, created_at: 1.hour.ago) }
    let!(:other_notification) { create(:notification, user: other_user) }

    context 'when authenticated' do
      it 'returns user notifications ordered by created_at desc' do
        get '/api/v1/notifications', headers: auth_headers(user)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['notifications'].size).to eq(2)
        expect(json['notifications'].first['id']).to eq(notification2.id)
        expect(json['unread_count']).to eq(1)
      end

      it 'filters by unread notifications' do
        get '/api/v1/notifications', params: { unread: 'true' }, headers: auth_headers(user)
        
        json = JSON.parse(response.body)
        expect(json['notifications'].size).to eq(1)
        expect(json['notifications'].first['id']).to eq(notification1.id)
      end

      it 'filters by notification type' do
        email_notification = create(:notification, user: user, notification_type: 'email')
        booking_notification = create(:notification, user: user, notification_type: 'booking')

        get '/api/v1/notifications', params: { type: 'email' }, headers: auth_headers(user)
        
        json = JSON.parse(response.body)
        notification_ids = json['notifications'].map { |n| n['id'] }
        expect(notification_ids).to include(email_notification.id)
        expect(notification_ids).not_to include(booking_notification.id)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get '/api/v1/notifications'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/notifications/:id' do
    let(:notification) { create(:notification, user: user) }

    context 'when authenticated' do
      it 'returns the notification' do
        get "/api/v1/notifications/#{notification.id}", headers: auth_headers(user)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['id']).to eq(notification.id)
        expect(json['title']).to eq(notification.title)
      end

      it 'returns not found for other user notification' do
        other_notification = create(:notification, user: other_user)
        get "/api/v1/notifications/#{other_notification.id}", headers: auth_headers(user)
        
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get "/api/v1/notifications/#{notification.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/notifications/:id/mark_as_read' do
    let(:notification) { create(:notification, user: user, read: false) }

    context 'when authenticated' do
      it 'marks notification as read' do
        patch "/api/v1/notifications/#{notification.id}/mark_as_read", headers: auth_headers(user)
        
        expect(response).to have_http_status(:ok)
        expect(notification.reload.read).to be true
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Notification marked as read')
      end

      it 'returns not found for other user notification' do
        other_notification = create(:notification, user: other_user)
        patch "/api/v1/notifications/#{other_notification.id}/mark_as_read", headers: auth_headers(user)
        
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        patch "/api/v1/notifications/#{notification.id}/mark_as_read"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/v1/notifications/:id/mark_as_unread' do
    let(:notification) { create(:notification, user: user, read: true) }

    context 'when authenticated' do
      it 'marks notification as unread' do
        patch "/api/v1/notifications/#{notification.id}/mark_as_unread", headers: auth_headers(user)
        
        expect(response).to have_http_status(:ok)
        expect(notification.reload.read).to be false
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Notification marked as unread')
      end
    end
  end

  describe 'PATCH /api/v1/notifications/mark_all_as_read' do
    let!(:unread1) { create(:notification, user: user, read: false) }
    let!(:unread2) { create(:notification, user: user, read: false) }
    let!(:already_read) { create(:notification, user: user, read: true) }

    context 'when authenticated' do
      it 'marks all notifications as read' do
        patch '/api/v1/notifications/mark_all_as_read', headers: auth_headers(user)
        
        expect(response).to have_http_status(:ok)
        expect(unread1.reload.read).to be true
        expect(unread2.reload.read).to be true
        json = JSON.parse(response.body)
        expect(json['message']).to eq('All notifications marked as read')
      end
    end
  end

  describe 'GET /api/v1/notifications/unread_count' do
    let!(:unread1) { create(:notification, user: user, read: false) }
    let!(:unread2) { create(:notification, user: user, read: false) }
    let!(:read_notification) { create(:notification, user: user, read: true) }

    context 'when authenticated' do
      it 'returns unread count' do
        get '/api/v1/notifications/unread_count', headers: auth_headers(user)
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['unread_count']).to eq(2)
      end
    end
  end

  describe 'DELETE /api/v1/notifications/:id' do
    let(:notification) { create(:notification, user: user) }

    context 'when authenticated' do
      it 'deletes the notification' do
        delete "/api/v1/notifications/#{notification.id}", headers: auth_headers(user)
        
        expect(response).to have_http_status(:ok)
        expect(Notification.exists?(notification.id)).to be false
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Notification deleted')
      end

      it 'returns not found for other user notification' do
        other_notification = create(:notification, user: other_user)
        delete "/api/v1/notifications/#{other_notification.id}", headers: auth_headers(user)
        
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        delete "/api/v1/notifications/#{notification.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
