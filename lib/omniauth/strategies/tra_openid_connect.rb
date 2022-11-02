module Omniauth
  module Strategies
    class TraOpenidConnect < OmniAuth::Strategies::OAuth2
      option :name, :identity

      option :client_options,
             {
               authorize_url: "/connect/authorize",
               site: ENV.fetch("TRA_OIDC_DOMAIN", nil),
               token_url: "/connect/token",
             }
      option :pkce, true
      option :scope,
             %i[email openid profile trn].join(" ") # This is a space separated string, comma separated will fail

      uid { raw_info["sub"] }

      info do
        {
          date_of_birth: parsed_date_of_birth,
          email: raw_info["email"],
          email_verified: parsed_email_verified,
          full_name: raw_info["name"],
          trn: raw_info["trn"],
        }
      end

      extra { { "raw_info" => raw_info } }

      def raw_info
        @raw_info ||= access_token.get("connect/userinfo").parsed
      end

      def parsed_date_of_birth
        raw_date_of_birth = raw_info["birthdate"]
        return if raw_date_of_birth.blank?

        Date.parse(raw_date_of_birth, "%Y-%m-%d")
      end

      def parsed_email_verified
        raw_info["email_verified"] == "True"
      end

      def build_access_token
        verifier = request.params["code"]
        redirect_uri = full_host + callback_path
        client.auth_code.get_token(
          verifier,
          { redirect_uri: }.merge(token_params.to_hash(symbolize_keys: true)),
          deep_symbolize(options.auth_token_params),
        )
      end
    end
  end
end
