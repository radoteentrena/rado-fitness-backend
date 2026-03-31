Rails.application.routes.draw do
  resource :onboarding, only: [:new, :create], controller: 'onboarding'
  get 'onboarding/success', to: 'onboarding#success', as: :onboarding_success

  get  "subscription/new",        to: "subscriptions#new",        as: :new_subscription
  post "subscription",            to: "subscriptions#create",     as: :subscriptions
  get  "subscription/processing", to: "subscriptions#processing", as: :subscriptions_processing

  namespace :admin do
      resources :coach_alerts
      resources :conversations, only: [:index, :show] do
        post :create_message
        delete :delete_message
      end
      resources :dietary_plans
      resources :exercises
      resources :phases, except:  [ :index ]
      resources :programs do
        resource :builder, only: [ :show ], controller: "program_builders"
        member do
          post :sync_sheet
        end
      end
      resources :routines do
        resources :workouts, only: [ :new, :create ]
      end
      resources :phase_routines, except: [ :index, :show ]
      resources :workouts, except: [ :index, :new, :create ]
      resources :workout_exercises, only: [ :edit, :update ]
      resources :users
      resources :user_dietary_plans, except: [ :index, :show ]
      resources :assignments, only: [ :new, :create ]
      resources :daily_metrics, only: [ :show ]
      # resources :messages  # Removed — use Conversations instead
      resources :progress_photos, except: [ :index ]
      resources :program_executions, except: [ :index ]
      resources :exercise_logs, except: [ :index ]
      resources :subscription_cancellations, only: [:create]
      resources :subscriptions, only: [:index, :show]

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
    post "mercadopago",       to: "mercadopago#create"
  end

  namespace :api do
    namespace :v1 do
      get "sync", to: "sync#index"
      post "auth/google", to: "auth#google"

      resources :exercises, only: [ :index ]
      resources :messages, only: [ :index, :create ]
      resources :daily_metrics, only: [ :create ]
      resources :progress_photos, only: [ :create ]
      resources :program_executions, only: [ :create ]

      namespace :training do
        get :current
        post :start
        post :complete
        post :skip
        get :history
      end
    end
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
