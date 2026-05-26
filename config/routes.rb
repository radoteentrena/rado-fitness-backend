Rails.application.routes.draw do
  resource :onboarding, only: [:new, :create], controller: 'onboarding'
  get 'onboarding/success', to: 'onboarding#success', as: :onboarding_success

  resource :booking, only: [:new, :create, :show]
  get "booking/availability", to: "booking_availability#show", as: :booking_availability

  get  "/pay/:token", to: "payments#show", as: :pay

  get  "subscription/new",        to: "subscriptions#new",        as: :new_subscription
  get  "subscription/frequency",  to: "subscriptions#frequency",  as: :subscription_frequency
  post "subscription",            to: "subscriptions#create",     as: :subscriptions
  get  "subscription/processing", to: "subscriptions#processing", as: :subscriptions_processing

  namespace :admin do
      resources :coach_alerts do
        member do
          patch :resolve
          patch :dismiss
          post  :send_message
        end
      end
      resources :conversations, only: [:index, :show, :new, :create] do
        post :create_message
        delete :delete_message
      end
      resources :dietary_plans
      resources :exercises
      resources :phases, except:  [ :index ]
      resources :programs do
        resource :builder, only: [ :show ], controller: "program_builders"
        resource :chat, controller: "program_chat", only: [ :show ] do
          post :message
          post :apply
        end
        member do
          post :sync_sheet
          delete :remove_user
        end
      end
      resources :routines do
        resources :workouts, only: [ :new, :create ]
      end
      resources :phase_routines, except: [ :index, :show ]
      resources :workouts, except: [ :index, :new, :create ] do
        resources :workout_exercises, only: [ :new, :create ]
      end
      resources :workout_exercises, only: [ :edit, :update, :destroy ] do
        member do
          get :swap
        end
      end
      resources :users do
        resource :program_assignment, only: [ :create ]
        resource :payment_link, only: [ :create ]
      end
      resources :user_dietary_plans, except: [ :index, :show ]
      resources :assignments, only: [ :new, :create ]
      resources :daily_metrics, only: [ :show ]
      # resources :messages  # Removed — use Conversations instead
      resources :progress_photos, except: [ :index ]
      resources :training_sessions, only: [ :show ]
      resources :subscription_cancellations, only: [:create]
      resources :subscriptions, only: [:index, :show]
      resources :coach_schedules, only: [:index, :edit, :update]
      get  "google_calendar/connect",  to: "google_calendar#connect",  as: :google_calendar_connect
      get  "google_calendar/callback", to: "google_calendar#callback",  as: :google_calendar_callback

      get  "ai_coach",          to: "ai_coach#new",      as: :new_ai_coach
      post "ai_coach/generate", to: "ai_coach#generate", as: :generate_ai_coach
      post "ai_coach/refine",   to: "ai_coach#refine",   as: :refine_ai_coach
      post "ai_coach/approve",  to: "ai_coach#approve",  as: :approve_ai_coach

      resources :books, only: [:index, :new, :create, :show]

      root to: "dashboard#index"
      get "dashboard", to: "dashboard#index"
    end

  devise_for :users, skip: [:registrations]

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
      post "auth/email", to: "auth#email"
      delete "auth/session", to: "auth#destroy"
      put "device_token", to: "device_tokens#update"

      resources :exercises, only: [ :index ]
      resources :messages, only: [ :index, :create ]
      resources :daily_metrics, only: [ :index, :create ]
      resources :progress_photos, only: [ :index, :create ]

      put "users/avatar",   to: "users#update_avatar"
      get "users/progress", to: "users#progress"

      namespace :training do
        get :current
        post :start
        put :log_exercise
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

  get "terminos",   to: "pages#terms",   as: :terms
  get "privacidad", to: "pages#privacy",  as: :privacy

  # Defines the root path route ("/")
  root "pages#home"
end
