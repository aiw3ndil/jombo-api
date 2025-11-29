Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
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
      end

      resources :bookings, only: [:index, :show, :create, :update, :destroy] do
        member do
          patch :confirm
          patch :reject
        end
      end
    end
  end
end
