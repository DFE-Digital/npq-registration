Rails.application.routes.draw do
  devise_for :users,
             controllers: { omniauth_callbacks: "omniauth" }

  get "/healthcheck", to: "monitoring#healthcheck", format: :json
  get "/up", to: "monitoring#up"

  resources :schools, only: [:index]
  resources :institutions, only: [:index]
  resources :private_childcare_providers, only: [:index]

  resources :email_updates do
    collection do
      get "unsubscribe"
      post "unsubscribe"
      get "unsubscribed"
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
    resources :schools, only: %i[index show]
  end

  get "/admin", to: "admin#show"

  namespace :api do
    get :guidance, to: "guidance#index"
    get "guidance/*page", to: "guidance#show", as: :guidance_page
    get "docs/:version", to: "documentation#index", as: :documentation

    namespace :v1 do
      namespace :get_an_identity do
        resource :webhook_messages, only: %i[create]
      end

      defaults format: :json do
        resources :applications, path: "npq-applications", only: %i[index show], param: :ecf_id do
          member do
            post :reject, path: "reject"
            post :accept, path: "accept"
            put :change_funded_place, path: "change-funded-place"
          end
        end

        resources :participant_outcomes, only: %i[index], path: "participants/npq/outcomes", as: :participant_outcomes

        resources :participants, only: %i[index show], path: "participants/npq", param: :ecf_id do
          member do
            put :change_schedule, path: "change-schedule"
            put :defer
            put :resume
            put :withdraw

            scope module: :participants do
              resources :outcomes, only: %i[create index], as: :participants_outcomes
            end
          end
        end

        resources :declarations, only: %i[create show index], path: "participant-declarations", param: :ecf_id do
          member do
            put :void, path: "void"
          end
        end
      end
    end

    namespace :v2, defaults: { format: :json } do
      resources :applications, path: "npq-applications", only: %i[index show], param: :ecf_id do
        member do
          post :reject, path: "reject"
          post :accept, path: "accept"
          put :change_funded_place, path: "change-funded-place"
        end
      end

      resources :enrolments, path: "npq-enrolments", only: %i[index]

      resources :participant_outcomes, only: %i[index], path: "participants/npq/outcomes", as: :participant_outcomes

      resources :participants, only: %i[index show], path: "participants/npq", param: :ecf_id do
        member do
          put :change_schedule, path: "change-schedule"
          put :defer
          put :resume
          put :withdraw

          scope module: :participants do
            resources :outcomes, only: %i[create index], as: :participants_outcomes
          end
        end
      end

      resources :declarations, only: %i[create show index], path: "participant-declarations", param: :ecf_id do
        member do
          put :void, path: "void"
        end
      end
    end

    namespace :v3, defaults: { format: :json } do
      resources :applications, path: "npq-applications", only: %i[index show], param: :ecf_id do
        member do
          post :reject, path: "reject"
          post :accept, path: "accept"
          put :change_funded_place, path: "change-funded-place"
        end
      end

      resources :participant_outcomes, only: %i[index], path: "participants/npq/outcomes", as: :participant_outcomes

      resources :participants, only: %i[index show], path: "participants/npq", param: :ecf_id do
        member do
          put :change_schedule, path: "change-schedule"
          put :defer
          put :resume
          put :withdraw

          scope module: :participants do
            resources :outcomes, only: %i[create index], as: :participants_outcomes
          end
        end
      end

      resources :declarations, only: %i[create show index], path: "participant-declarations", param: :ecf_id do
        member do
          put :void, path: "void"
          put :change_delivery_partner, path: "change-delivery-partner"
        end
      end

      resources :statements, only: %i[index show], param: :ecf_id

      resources :delivery_partners, path: "delivery-partners", only: %i[index show], param: :ecf_id
    end

    namespace :teacher_record_service, path: "teacher-record-service", defaults: { format: :json } do
      namespace :v1 do
        resources :qualifications, only: %i[show], param: :trn
      end
    end
  end

  namespace :npq_separation, path: "npq-separation" do
    get "admin", to: "admin/dashboards/summary#show"

    namespace :admin do
      namespace :settings do
        resources :webhook_messages, only: %i[index show], path: "webhook-messages" do
          resources :processing_jobs, only: %i[create], controller: "webhook_messages/processing_jobs", path: "processing-jobs"
        end
      end

      resources :features, only: %i[index show update]
      resources :admins, only: %i[index new create destroy]
      resources :super_admins, only: %i[update]
      namespace :dashboards do
        resource :summary, only: :show, controller: "summary"
      end

      resources :reopening_email_subscriptions do
        member do
          get "unsubscribe"
          post "unsubscribe"
        end
        collection do
          get "all_users"
          get "senco"
        end
      end

      resources :closed_registration_users do
        member do
          get "destroy"
          delete "destroy"
        end
      end

      resources :applications, only: %i[index show] do
        collection do
          resources :reviews, controller: "applications/reviews", as: "application_reviews", only: %i[index show] do
            resource :review_status, controller: "applications/review_statuses", only: %i[edit update]
          end
        end
        member do
          namespace :applications, path: nil do
            resource :revert_to_pending, controller: "revert_to_pending", only: %i[new create]
            resource :change_training_status, only: %i[new create]
            resource :change_funding_eligibility, only: %i[new create]
            resource :change_lead_provider, controller: "change_lead_provider", only: %i[show create]
            resource :notes, only: %i[edit update]
            resource :change_cohort, controller: "change_cohort", only: %i[show create]
          end
        end
      end

      resources :cohorts do
        resources :schedules, except: :index
        resources :statements, only: %i[new create show]
      end

      resources :delivery_partners, path: "delivery-partners", except: %i[show destroy] do
        resource :delivery_partnerships, path: "delivery-partnerships", only: :edit
      end

      resources :schools, only: %i[index show]
      resources :courses, only: %i[index show]
      resources :users, only: %i[index show] do
        member do
          namespace :users, path: nil do
            resource :change_trn, controller: "change_trn", only: %i[show create]
          end
        end
      end

      resources :participant_outcomes, only: %i[] do
        member { post :resend }
      end

      namespace :finance do
        resources :statements, only: %i[index show] do
          resources :adjustments, controller: "statements/adjustments" do
            collection do
              post :add_another
            end

            member do
              get :delete
            end
          end

          member do
            resource :assurance_report, controller: "statements/assurance_reports", only: "show"
            resource :payment_authorisation, controller: "statements/payment_authorisations", only: %i[new create]
            resources :voided, controller: "statements/voided", only: :index
          end
        end
      end

      resources :lead_providers, only: %i[index show], path: "lead-providers" do
        resources :cohort, controller: "lead_provider_cohort", only: %i[show]
      end
      resources :admins, only: %i[index]

      resources :bulk_operations, only: %i[index], path: "bulk-operations"

      namespace :bulk_operations, path: "bulk-operations" do
        resources :revert_applications_to_pending, controller: "revert_applications_to_pending", only: %i[index create show] do
          post "run", on: :member
        end

        resources :reject_applications, controller: "reject_applications", only: %i[index create show] do
          post "run", on: :member
        end

        resources :update_and_verify_trns, controller: "update_and_verify_trns", only: %i[index create show] do
          post "run", on: :member
        end
      end
    end
  end

  get "maintenance_banners/dismiss", to: "maintenance_banners#dismiss", as: :maintenance_banner_dismiss

  get "/404", to: "errors#not_found", via: :all
  get "/422", to: "errors#unprocessable_entity", via: :all
  get "/500", to: "errors#internal_server_error", via: :all

  constraints(->(request) { Admin.find_by(id: request.session[:admin_id])&.super_admin? }) do
    mount DelayedJobWeb, at: "/delayed_job"
  end

  get "/development_login", to: "registration_wizard#development_login"
end
