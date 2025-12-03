Rails.application.routes.draw do
  # Health check endpoints
  get '/health', to: 'health#index'
  get '/health/database', to: 'health#database'
  
  namespace :api do
    namespace :v1 do
      post 'login', to: 'sessions#create'
      post 'register', to: 'registrations#create'
      delete 'logout', to: 'sessions#destroy'
      get 'me', to: 'sessions#me'
      
      resources :trips do
        collection do
          get 'search/:departure_location', to: 'trips#search', as: 'search'
          get 'my_trips', to: 'trips#my_trips'
        end
        resources :bookings, only: [:index], controller: 'trip_bookings'
        get 'conversation', to: 'conversations#show_by_trip'
      end

      resources :bookings, only: [:index, :show, :create, :update, :destroy] do
        member do
          patch :confirm
          patch :reject
        end
        resources :reviews, only: [:create] do
          collection do
            get '', to: 'reviews#booking_reviews', as: ''
          end
        end
      end
      
      resources :conversations, only: [:index, :show, :destroy] do
        resources :messages, only: [:index, :create, :destroy]
      end
      
      namespace :users do
        patch 'profile', to: 'profile#update'
      end
      
      get 'users/:user_id/reviews', to: 'reviews#index', as: 'user_reviews'
    end
  end
end
