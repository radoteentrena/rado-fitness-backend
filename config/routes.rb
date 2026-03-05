Rails.application.routes.draw do
  resource :onboarding, only: [:new, :create], controller: 'onboarding'
  get 'onboarding/success', to: 'onboarding#success', as: :onboarding_success

  namespace :admin do
      resources :coach_alerts
      resources :coach_alerts
      resources :dietary_plans
      resources :exercises
      resources :programs
      resources :routines

      resources :users
      resources :assignments, only: [:new, :create]
      resources :daily_metrics, only: [:show]

      root to: "dashboard#index"
      get "dashboard", to: "dashboard#index"
    end

  devise_for :users

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Webhooks
  namespace :webhooks do
    post "whatsapp/incoming", to: "whatsapp#incoming"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"
end
