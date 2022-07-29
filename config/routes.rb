Rails.application.routes.draw do
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

  get "/session/:step", to: "session_wizard#show", as: "session_wizard_show"
  patch "/session/:step", to: "session_wizard#update", as: "session_wizard_update"

  resource :account

  get "/cookies", to: "pages#show", page: "cookies"
  get "/privacy-policy", to: "pages#show", page: "privacy_policy"
  get "/accessibility-statement", to: "pages#show", page: "accessibility"

  get "/faqs/early-years", to: "pages#show", page: "faqs/early-years"
  get "/faqs/schools", to: "pages#show", page: "faqs/schools"
  get "/faqs/other-users", to: "pages#show", page: "faqs/other-users"

  resource :cookie_preferences do
    member do
      post "hide"
    end
  end

  namespace :admin do
    resources :applications, only: %i[index show]
  end

  get "/admin", to: "admin#show"

  resource :csp_reports, only: %i[create]

  get "/404", to: "errors#not_found", via: :all
  get "/422", to: "errors#unprocessable_entity", via: :all
  get "/500", to: "errors#internal_server_error", via: :all
end
