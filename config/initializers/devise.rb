# frozen_string_literal: true

require "omniauth/strategies/tra_openid_connect"

Devise.setup do |config|
  require "devise/orm/active_record"

  if Rails.env.test?
    config.secret_key = "devisebequiet1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111"
  end

  config.omniauth :tra_openid_connect,
                  allow_authorize_params: %i[request_email_updates],
                  callback_path: "/users/auth/tra_openid_connect/callback",
                  client_options: {
                    host: URI(ENV["TRA_OIDC_DOMAIN"]).host,
                    identifier: ENV.fetch("TRA_OIDC_CLIENT_ID"),
                    redirect_uri:
                      "#{ENV.fetch("HOSTING_DOMAIN")}/users/auth/tra_openid_connect/callback",
                    secret: ENV.fetch("TRA_OIDC_CLIENT_SECRET"),
                  },
                  issuer: ENV.fetch("TRA_OIDC_DOMAIN"),
                  post_logout_redirect_uri:
                    "#{ENV.fetch("HOSTING_DOMAIN")}/sign-out",
                  strategy_class: Omniauth::Strategies::TraOpenidConnect
end
