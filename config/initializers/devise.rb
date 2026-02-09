# frozen_string_literal: true

require "omniauth/strategies/tra_openid_connect"
require "omniauth/strategies/teacher_auth"

Devise.setup do |config|
  require "devise/orm/active_record"

  if Rails.env.test?
    config.secret_key = "devisebequiet1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111"
  end

  oidc_domain = ENV["TRA_OIDC_DOMAIN"].presence

  config.omniauth :tra_openid_connect,
                  allow_authorize_params: %i[request_email_updates],
                  callback_path: "/users/auth/tra_openid_connect/callback",
                  client_options: {
                    host: oidc_domain ? URI(oidc_domain).host : nil,
                    identifier: ENV.fetch("TRA_OIDC_CLIENT_ID"),
                    redirect_uri:
                      "#{ENV.fetch('HOSTING_DOMAIN')}/users/auth/tra_openid_connect/callback",
                    secret: ENV.fetch("TRA_OIDC_CLIENT_SECRET"),
                  },
                  issuer: oidc_domain,
                  post_logout_redirect_uri:
                    "#{ENV.fetch('HOSTING_DOMAIN')}/sign-out",
                  strategy_class: Omniauth::Strategies::TraOpenidConnect

  if Rails.configuration.x.teacher_auth.enabled
    teacher_auth_domain = Rails.configuration.x.teacher_auth.domain

    config.omniauth :teacher_auth,
                    callback_path: "/users/auth/teacher_auth/callback",
                    client_options: {
                      host: teacher_auth_domain ? URI(teacher_auth_domain).host : nil,
                      identifier: Rails.configuration.x.teacher_auth.client_id,
                      redirect_uri: "#{ENV.fetch('HOSTING_DOMAIN')}/users/auth/teacher_auth/callback",
                      secret: Rails.configuration.x.teacher_auth.client_secret,
                    },
                    issuer: teacher_auth_domain,
                    post_logout_redirect_uri: "#{ENV.fetch('HOSTING_DOMAIN')}/sign-out",
                    strategy_class: Omniauth::Strategies::TeacherAuth
  end
end
