Rails.application.routes.draw do
  devise_for :users,
             controllers: { omniauth_callbacks: "omniauth" }

  get "/healthcheck", to: "monitoring#healthcheck", format: :json

  resources :schools, only: [:index]
  resources :institutions, only: [:index]
  resources :private_childcare_providers, only: [:index]

  resources :email_updates do
    collection do
      get "unsubscribe"
    end
  end

  resource :registration_closed, only: [:show], controller: :registration_closed do
    collection do
      get "change"
    end
  end

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
  get "/privacy-policy", to: redirect("https://www.gov.uk/government/publications/privacy-information-education-providers-workforce-including-teachers/privacy-information-education-providers-workforce-including-teachers#NPQ"), as: :privacy_policy
  get "/accessibility-statement", to: "pages#show", page: "accessibility"
  get "/choose-an-npq-and-provider", to: "pages#show", page: "choose_an_npq_and_provider"
  get "/closed_registration_exception", to: "pages#show", page: "closed_registration_exception"

  resource :cookie_preferences do
    member do
      post "hide"
    end
  end

  namespace :admin do
    resources :applications, only: %i[index show] do
      # This routes are only written for review apps in order to update the external statuses
      member do
        patch "update_approval_status"
        patch "update_participant_outcome"
      end
    end
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

    constraints HasFlipperAccess do
      mount Flipper::UI.app(Flipper) => "/feature_flags"
    end

    resources "settings"
    resources :closed_registration_users
  end

  get "/admin", to: "admin#show"

  namespace :api do
    constraints -> { Rails.application.config.npq_separation[:api_enabled] } do
      get :guidance, to: "guidance#index"
      get "guidance/*page", to: "guidance#show", as: :guidance_page
      get "docs/:version", to: "documentation#index", as: :documentation
    end

    namespace :v1 do
      namespace :get_an_identity do
        resource :webhook_messages, only: %i[create]
      end

      constraints -> { Rails.application.config.npq_separation[:api_enabled] } do
        defaults format: :json do
          resources :applications, path: "npq-applications", only: %i[index show] do
            post :reject, path: "reject"
            post :accept, path: "accept"
          end

          resources :participants, only: %i[index show], path: "participants/npq" do
            put :change_schedule, path: "change-schedule"
            put :defer
            put :resume
            put :withdraw
            get :outcomes
          end

          resources :outcomes, only: %i[index]

          resources :declarations, only: %i[create show index] do
            put :void, path: "void"
          end
        end
      end
    end

    namespace :v2, defaults: { format: :json }, constraints: ->(_request) { Rails.application.config.npq_separation[:api_enabled] } do
      resources :applications, path: "npq-applications", only: %i[index show] do
        post :reject, path: "reject"
        post :accept, path: "accept"
      end

      resources :enrolments, path: "npq-enrolments", only: %i[index]

      resources :participants, only: %i[index show], path: "participants/npq" do
        put :change_schedule, path: "change-schedule"
        put :defer
        put :resume
        put :withdraw

        scope module: :participants do
          resources :outcomes, only: %i[create index]
        end
      end

      resources :outcomes, only: %i[index]

      resources :declarations, only: %i[create show index] do
        put :void, path: "void"
      end
    end

    namespace :v3, defaults: { format: :json }, constraints: ->(_request) { Rails.application.config.npq_separation[:api_enabled] } do
      resources :applications, path: "npq-applications", only: %i[index show] do
        post :reject, path: "reject"
        post :accept, path: "accept"
      end

      resources :participants, only: %i[index show], path: "participants/npq" do
        put :change_schedule, path: "change-schedule"
        put :defer
        put :resume
        put :withdraw

        scope module: :participants do
          resources :outcomes, only: %i[create index]
        end
      end

      resources :outcomes, only: %i[index]

      resources :declarations, only: %i[create show index] do
        put :void, path: "void"
      end

      resources :statements, only: %i[index show]
    end
  end

  namespace :npq_separation, path: "npq-separation" do
    constraints(->(_request) { Rails.application.config.npq_separation[:admin_portal_enabled] }) do
      get "admin", to: "admin/dashboards/summary#show"
      namespace :admin do
        namespace :dashboards do
          resource :summary, only: :show, controller: "summary"
        end

        resources :applications, only: %i[index]
        resources :users, only: %i[index show]

        namespace :finance do
          resources :statements, only: %i[index show] do
            collection do
              resources :unpaid, controller: "statements/unpaid", only: "index"
              resources :paid, controller: "statements/paid", only: "index"
            end
          end
        end

        resources :lead_providers, only: %i[index show], path: "lead-providers"
        resources :admins, only: %i[index]
      end
    end

    namespace :migration, constraints: ->(_request) { Rails.application.config.npq_separation[:migration_enabled] } do
      resources :migrations, only: %i[index create]
    end
  end

  resource :csp_reports, only: %i[create]

  get "/404", to: "errors#not_found", via: :all
  get "/422", to: "errors#unprocessable_entity", via: :all
  get "/500", to: "errors#internal_server_error", via: :all

  authenticated :user, ->(user) { user.super_admin? } do
    mount DelayedJobWeb, at: "/delayed_job"
  end
end
