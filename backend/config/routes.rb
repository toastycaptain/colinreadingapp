Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config.merge(sign_out_via: [:delete, :post])
  ActiveAdmin.routes(self)
  get "up" => "rails/health#show", as: :rails_health_check
  post "/webhooks/mux", to: "webhooks/mux#receive"

  devise_for :users, skip: :all

  devise_scope :user do
    post "api/v1/auth/register", to: "api/v1/auth/registrations#create"
    post "api/v1/auth/login", to: "api/v1/auth/sessions#create"
    delete "api/v1/auth/logout", to: "api/v1/auth/sessions#destroy"
    post "api/v1/auth/logout", to: "api/v1/auth/sessions#destroy"
  end

  namespace :api do
    namespace :v1 do
      resources :children, only: [:index, :create, :update] do
        get :library, to: "library#index"
        post :library_items, to: "library_items#create"
        delete "library_items/:book_id", to: "library_items#destroy"
        post :playback_sessions, to: "playback_sessions#create"
      end

      namespace :catalog do
        resources :books, only: [:index]
      end

      resources :usage_events, only: [:create]
    end
  end

  namespace :admin do
    namespace :api do
      namespace :v1 do
        post "mux/direct_uploads", to: "mux#direct_upload"
        get "reports/usage", to: "reports#usage"
      end
    end
  end
end
