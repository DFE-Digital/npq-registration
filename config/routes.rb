Rails.application.routes.draw do
  devise_for :users,
             controllers: { omniauth_callbacks: "omniauth" }

  get "/healthcheck", to: "monitoring#healthcheck", format: :json

  resources :schools, only: [:index]
  resources :institutions, only: [:index]
  resources :private_childcare_providers, only: [:index]

  root "registration_wizard#show", step: "start"

  get "/registration/:step", to: "registration_wizard#show", as: "registration_wizard_show"
  get "/registration/:step/change", to: "registration_wizard#show", as: "registration_wizard_show_change", changing_answer: "1"
  patch "/registration/:step", to: "registration_wizard#update", as: "registration_wizard_update"
  patch "/registration/:step/change", to: "registration_wizard#update", as: "registration_wizard_update_change", changing_answer: "1"

  get "/registration-interest/sign-up", to: "interest_notification_sign_up#new"
  post "/registration-interest/sign-up", to: "interest_notification_sign_up#create"
  get "/registration-interest/sign-up/confirm", to: "interest_notification_sign_up#confirm"

  get "/sign-in", to: "session_wizard#show", step: "sign_in"
  get "/sign-out", to: "sessions#destroy", as: "sign_out_user"

  get "/session/:step", to: "session_wizard#show", as: "session_wizard_show"
  patch "/session/:step", to: "session_wizard#update", as: "session_wizard_update"

  resource :account

  namespace :accounts do
    resources :user_registrations, only: [:show]
  end

  get "/cookies", to: "pages#show", page: "cookies"
  get "/privacy-policy", to: "pages#show", page: "privacy_policy"
  get "/accessibility-statement", to: "pages#show", page: "accessibility"
  get "/choose-an-npq-and-provider", to: "pages#show", page: "choose_an_npq_and_provider"

  resource :cookie_preferences do
    member do
      post "hide"
    end
  end

  namespace :admin do
    resources :applications, only: %i[index show]
    resources :unsynced_applications, only: %i[index], path: "unsynced-applications"

    resources :users, only: %i[index show] do
      resources :application_submissions, only: %i[create]
    end

    resources :unsynced_users, only: %i[index], path: "unsynced-users"

    resources :schools, only: %i[index show]

    resources :admins, only: %i[index new create destroy]
    resources :super_admins, only: %i[update]

    resources :webhook_messages, only: %i[index show] do
      resources :processing_jobs, only: %i[create], controller: "webhook_messages/processing_jobs"
    end

    constraints RouteConstraints::HasFlipperAccess do
      mount Flipper::UI.app(Flipper) => "/feature_flags"
    end
  end

  get "/admin", to: "admin#show"

  namespace :api do
    namespace :v1 do
      namespace :get_an_identity do
        resource :webhook_messages, only: %i[create]
      end
    end
  end

  resource :csp_reports, only: %i[create]

  get "/404", to: "errors#not_found", via: :all
  get "/422", to: "errors#unprocessable_entity", via: :all
  get "/500", to: "errors#internal_server_error", via: :all

  authenticate :user, ->(u) { u.super_admin? } do
    mount Coverband::Reporters::Web.new, at: "/coverage"
  end
end
