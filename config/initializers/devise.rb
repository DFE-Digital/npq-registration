# frozen_string_literal: true

require "omniauth/strategies/tra_openid_connect"

Devise.setup do |config|
  require "devise/orm/active_record"

  if Rails.env.test?
    config.secret_key = "devisebequiet1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111"
  end

  # ==> OmniAuth
  tra_oidc_secret  = ENV.fetch("TRA_OIDC_CLIENT_SECRET", nil)
  tra_oidc_id      = ENV.fetch("TRA_OIDC_CLIENT_ID", nil)

  config.omniauth :tra_openid_connect,
                  tra_oidc_id,
                  tra_oidc_secret,
                  name: :tra_openid_connect,
                  client_options: {
                    identifier: tra_oidc_id,
                    secret: tra_oidc_secret,
                  }
end
