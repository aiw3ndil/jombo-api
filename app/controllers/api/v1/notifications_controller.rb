module Api
  module V1
    class NotificationsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_notification, only: [:show, :mark_as_read, :mark_as_unread]

      def index
        notifications = current_user.notifications.recent
        
        # Filtros opcionales
        notifications = notifications.unread if params[:unread] == 'true'
        notifications = notifications.where(notification_type: params[:type]) if params[:type].present?
        
        render json: {
          notifications: notifications,
          unread_count: current_user.notifications.unread.count
        }
      end

      def show
        render json: @notification
      end

      def mark_as_read
        if @notification.mark_as_read!
          render json: { message: 'Notification marked as read', notification: @notification }
        else
          render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def mark_as_unread
        if @notification.mark_as_unread!
          render json: { message: 'Notification marked as unread', notification: @notification }
        else
          render json: { errors: @notification.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def mark_all_as_read
        NotificationService.mark_all_as_read(current_user)
        render json: { message: 'All notifications marked as read' }
      end

      def unread_count
        render json: { unread_count: current_user.notifications.unread.count }
      end

      def destroy
        @notification = current_user.notifications.find(params[:id])
        @notification.destroy
        render json: { message: 'Notification deleted' }
      end

      private

      def set_notification
        @notification = current_user.notifications.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Notification not found' }, status: :not_found
      end
    end
  end
end
