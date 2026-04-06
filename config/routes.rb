Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # ── Authentication ──
  get    "login",  to: "sessions#new"
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  get   "forgot-password",        to: "password_resets#new",    as: :new_password_reset
  post  "forgot-password",        to: "password_resets#create"
  get   "reset-password/:token",  to: "password_resets#edit",   as: :edit_password_reset
  patch "reset-password/:token",  to: "password_resets#update", as: :password_reset

  # ── Admin ──
  namespace :admin do
    root "dashboard#index"

    resources :monitoring_stations, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]
    resources :alarms do
      resources :alarm_actions, only: [ :new, :create, :edit, :update, :destroy ]
      member do
        get :history
        patch :enable
        patch :disable
      end
    end
    resources :river_basins, only: [ :index, :show, :new, :create, :edit, :update, :destroy ]
    resources :users, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resource :weather, only: [ :show ], controller: "weather"

    mount MissionControl::Jobs::Engine, at: "/jobs"
  end

  # ── Public ──
  root "public/home#index"

  scope module: :public do
    get "mapa",      to: "risk_map#index",    as: :risk_map
    get "alertas",   to: "alarms#index",      as: :public_alarms
    get "bairros",   to: "neighborhoods#index", as: :neighborhoods
    get "bairros/:code", to: "neighborhoods#show", as: :neighborhood
    get "seguranca", to: "safety#index",      as: :safety
  end
end
