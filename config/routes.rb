Rails.application.routes.draw do
  # Health check endpoints
  get '/health', to: 'health#index'
  get '/health/database', to: 'health#database'

  namespace :api do
    namespace :v1 do
      # Auth
      post 'login', to: 'sessions#create'
      post 'register', to: 'registrations#create'
      delete 'logout', to: 'sessions#destroy'
      get 'me', to: 'sessions#me'

      # OAuth
      post 'auth/:provider', to: 'oauth#create'

      # Trips and nested bookings
      resources :trips do
        collection do
          get 'search/:departure_location', to: 'trips#search', as: 'search'
          get 'my_trips', to: 'trips#my_trips'
        end

        # Nested bookings
        resources :bookings, only: [:index, :create] do
          member do
            put :confirm
            put :reject
          end
        end

        # Trip conversations
        get 'conversation', to: 'conversations#show_by_trip'
      end

      # Standalone bookings routes (for show, update, destroy)
      resources :bookings, only: [:index, :show, :update, :destroy] do
        # Reviews on a booking
        resources :reviews, only: [:create] do
          collection do
            get '', to: 'reviews#booking_reviews', as: ''
          end
        end
      end

      # Conversations and messages
      resources :conversations, only: [:index, :show, :destroy] do
        resources :messages, only: [:index, :create, :destroy]
      end

      # User profile
      namespace :users do
        patch 'profile', to: 'profile#update'
      end

      # Notifications
      resources :notifications, only: [:index, :show, :destroy] do
        member do
          patch :mark_as_read
          patch :mark_as_unread
        end
        collection do
          patch :mark_all_as_read
          get :unread_count
        end
      end

      # Reviews by user
      get 'users/:user_id/reviews', to: 'reviews#index', as: 'user_reviews'
    end
  end
end
