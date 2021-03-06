Rails.application.routes.draw do
  resources :errors, only: [:show]
  resources :teams, only: [:index, :show, :update] do
    member do
      get "typeahead/:query" => "teams#typeahead", :defaults => { format: "json" }
    end
  end
  get "/teams/typeahead/:query" => "teams#all_with_query", :defaults => { format: "json" }

  resources :help, only: [:index]

  resources :team_users, only: [:create, :destroy, :update]
  resources :namespaces, only: [:index, :show, :update] do
    put "change_visibility", on: :member
    resources :webhooks do
      resources :headers, only: [:create, :destroy], controller: :webhook_headers
      resources :deliveries, only: [:update], controller: :webhook_deliveries
      member do
        put "toggle_enabled"
      end
    end
  end
  get "namespaces/typeahead/:query" => "namespaces#typeahead", :defaults => { format: "json" }

  resources :repositories, only: [:index, :show, :destroy] do
    post :toggle_star, on: :member
    resources :comments, only: [:create, :destroy]
  end

  resources :tags, only: [:show, :destroy]

  resources :application_tokens, only: [:create, :destroy]

  devise_for :users, controllers: { registrations:      "auth/registrations",
                                    sessions:           "auth/sessions",
                                    passwords:          "passwords",
                                    omniauth_callbacks: "auth/omniauth_callbacks" }
  resource :dashboard, only: [:index]
  resources :search, only: [:index]
  resources :explore, only: [:index]

  # Health check
  get "/_ping", to: "health#index"
  get "/_health", to: "health#health"

  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  devise_scope :user do
    root to: "auth/sessions#new"
    put "toggle_enabled/:id", to: "auth/registrations#toggle_enabled", as: :toggle_enabled
  end

  namespace :v2, module: "api/v2", defaults: { format: :json } do
    root to: "ping#ping", as: :ping
    resource :token, only: [:show]
    resource :webhooks, only: [] do
      resources :events, only: [:create]
    end
  end

  mount API::RootAPI => "/"
  mount GrapeSwaggerRails::Engine, at: "/api/documentation" unless Rails.env.production?

  get "users/oauth", to: "auth/omniauth_registrations#new"
  post "users/oauth", to: "auth/omniauth_registrations#create"

  namespace :admin do
    resources :activities, only: [:index]
    resources :dashboard, only: [:index]
    resources :registries, except: [:show, :destroy]
    resources :namespaces, only: [:index]
    resources :teams, only: [:index]
    resources :users do
      put "toggle_admin", on: :member
    end
  end

  # Error pages.
  %w[401 404 422 500].each do |code|
    get "/#{code}", to: "errors#show", status: code
  end
end
