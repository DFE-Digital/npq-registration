Rails.application.routes.draw do
  devise_for :users

  root "registration_wizard#show", step: "start"

  get "/registration/:step", to: "registration_wizard#show", as: "registration_wizard_show"
  patch "/registration/:step", to: "registration_wizard#update", as: "registration_wizard_update"

  get "/sign-in", to: "sessions#new"

  get "/pages/:page", to: "pages#show"

  get "/healthcheck", to: "monitoring#healthcheck", format: :json

  get "/404", to: "errors#not_found", via: :all
  get "/422", to: "errors#unprocessable_entity", via: :all
  get "/500", to: "errors#internal_server_error", via: :all
end
