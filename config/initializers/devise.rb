# frozen_string_literal: true

require "omniauth/strategies/tra_openid_connect"

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
                    identifier: ENV.fetch("TRA_OIDC_CLIENT_ID", nil),
                    redirect_uri:
                      "#{ENV.fetch("HOSTING_DOMAIN", nil)}/users/auth/tra_openid_connect/callback",
                    secret: ENV.fetch("TRA_OIDC_CLIENT_SECRET", nil),
                  },
                  issuer: oidc_domain,
                  post_logout_redirect_uri:
                    "#{ENV.fetch("HOSTING_DOMAIN", nil)}/sign-out",
                  strategy_class: Omniauth::Strategies::TraOpenidConnect
end
