Rails.application.routes.draw do
  require "sidekiq/web"

  devise_for :admin_users, ActiveAdmin::Devise.config.merge(sign_out_via: [:delete, :post])
  ActiveAdmin.routes(self)
  authenticate :admin_user, lambda { |admin| admin.super_admin? } do
    mount Sidekiq::Web => "/admin/sidekiq"
  end
  get "up" => "rails/health#show", as: :rails_health_check
  post "/webhooks/mux", to: "webhooks/mux#receive"

  devise_for :users, skip: :all

  devise_scope :user do
    post "api/v1/auth/register", to: "api/v1/auth/registrations#create"
    post "api/v1/auth/login", to: "api/v1/auth/sessions#create"
    delete "api/v1/auth/logout", to: "api/v1/auth/sessions#destroy"
    post "api/v1/auth/logout", to: "api/v1/auth/sessions#destroy"
    post "api/v1/auth/password/forgot", to: "api/v1/auth/passwords#forgot"
    post "api/v1/auth/password/reset", to: "api/v1/auth/passwords#reset"
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
        resources :books, only: [:index, :show]
        resources :categories, only: [:index]
      end

      namespace :compliance do
        resource :privacy_policy, only: [:show]
        resources :consents, only: [:create]
        resources :deletion_requests, only: [:index, :create]
      end

      resources :usage_events, only: [:create]
    end
  end

  namespace :admin do
    namespace :api do
      namespace :v1 do
        post "mux/direct_uploads", to: "mux#direct_upload"
        get "reports/usage", to: "reports#usage"
        get "reports/analytics", to: "reports#analytics"
        resources :payout_periods, only: [:create, :show] do
          member do
            post :generate_statements
            post :mark_paid
          end
        end
      end
    end
  end
end
