Rails.application.routes.draw do
  root "pages#start"
  get "/start", to: "pages#start"

  get "/registration/:step", to: "registration_wizard#show", as: "registration_wizard_show"
  put "/registration/:step", to: "registration_wizard#update", as: "registration_wizard_update"

  get "/pages/:page", to: "pages#show"

  get "/404", to: "errors#not_found", via: :all
  get "/422", to: "errors#unprocessable_entity", via: :all
  get "/500", to: "errors#internal_server_error", via: :all
end
