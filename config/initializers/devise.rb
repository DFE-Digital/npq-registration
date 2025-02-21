# frozen_string_literal: true

Devise.setup do |config|
  require "devise/orm/active_record"

  if Rails.env.test?
    config.secret_key = "devisebequiet1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111"
  end

  config.omniauth :openid_connect,
                  name: :tra_openid_connect,
                  allow_authorize_params: %i[prompt],
                  callback_path: "/users/auth/tra_openid_connect/callback",
                  client_options: {
                    host: URI(ENV["TRA_OIDC_DOMAIN"]).host,
                    identifier: ENV.fetch("TRA_OIDC_CLIENT_ID"),
                    port: 443,
                    redirect_uri: ENV.fetch("TRA_OIDC_REDIRECT_URI"),
                    scheme: "https",
                    secret: ENV.fetch("TRA_OIDC_CLIENT_SECRET"),
                  },
                  discovery: true,
                  issuer: ENV.fetch("TRA_OIDC_DOMAIN"),
                  path_prefix: "/users/auth",
                  pkce: true,
                  # post_logout_redirect_uri: # TODO
                  #   "#{ENV["HOSTING_DOMAIN"]}/qualifications/sign-out",
                  response_type: :code,
                  scope: %w[email openid profile trn]
end
