Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config.merge(sign_out_via: [:delete, :post])
  ActiveAdmin.routes(self)
  get "up" => "rails/health#show", as: :rails_health_check

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
        post "uploads/master_video", to: "uploads#master_video"
        get "reports/usage", to: "reports#usage"

        resources :books, only: [] do
          resources :video_assets, only: [:create]
        end

        resources :video_assets, only: [] do
          member do
            post :retry_processing
            post :poll_status
          end
        end
      end
    end
  end
end
