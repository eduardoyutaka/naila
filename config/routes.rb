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

  # ── Admin ──
  namespace :admin do
    root "dashboard#index"

    resources :monitoring_stations, only: [:index, :show, :new, :create, :edit, :update, :destroy]
    resources :alerts, only: [:index, :show, :new, :create] do
      member do
        patch :acknowledge
        patch :resolve
      end
    end
    resources :alert_thresholds, only: [:new, :create, :edit, :update, :destroy]
    resources :river_basins, only: [:index, :show, :new, :create, :edit, :update, :destroy]
    resources :users, only: [:index, :new, :create, :edit, :update, :destroy]
  end

  # ── Public ──
  root "public/home#index"

  scope module: :public do
    get "mapa",      to: "risk_map#index",    as: :risk_map
    get "alertas",   to: "alerts#index",      as: :public_alerts
    get "bairros",   to: "neighborhoods#index", as: :neighborhoods
    get "bairros/:code", to: "neighborhoods#show", as: :neighborhood
    get "seguranca", to: "safety#index",      as: :safety
  end
end
