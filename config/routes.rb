Rails.application.routes.draw do
  namespace :admin do
      resources :coach_alerts
      resources :dietary_plans
      resources :exercises
      resources :phases, except: [:index]
      resources :programs do
        resource :builder, only: [:show], controller: 'program_builders'
        member do
          post :sync_sheet
        end
      end
      resources :routines
      resources :phase_routines, except: [:index, :show]
      resources :routine_exercises, only: [ :edit, :update ]
      resources :users
      resources :user_dietary_plans, except: [:index, :show]
      resources :assignments, only: [ :new, :create ]
      resources :daily_metrics, only: [ :show ]

      get  "ai_coach",          to: "ai_coach#new",      as: :new_ai_coach
      post "ai_coach/generate", to: "ai_coach#generate", as: :generate_ai_coach
      post "ai_coach/refine",   to: "ai_coach#refine",   as: :refine_ai_coach
      post "ai_coach/approve",  to: "ai_coach#approve",  as: :approve_ai_coach

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
  # root "posts#index"
end
