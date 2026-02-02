Rails.application.routes.draw do
  namespace :coach do
    get "dashboards/show"
  end
  devise_for :users
  mount_avo
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Webhooks
  namespace :webhooks do
    post "whatsapp/incoming", to: "whatsapp#incoming"
  end

  namespace :coach do
    resource :dashboard, only: [:show]
  end
  # Shortcut
  get "dashboard", to: "coach/dashboards#show", as: :dashboard

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end

if defined? ::Avo
  Avo::Engine.routes.draw do
    # This route is not protected, secure it with authentication if needed.
    get "coach_dashboard", to: "tools#coach_dashboard", as: :coach_dashboard
  end
end
