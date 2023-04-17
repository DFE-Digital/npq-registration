module External
  module GetAnIdentity
    class AccessToken
      attr_reader :token

      def initialize
        client_id = ENV.fetch("TRA_OIDC_CLIENT_ID")
        client_secret = ENV.fetch("TRA_OIDC_CLIENT_SECRET")
        client_url = ENV.fetch("TRA_OIDC_DOMAIN")
        client = OAuth2::Client.new(client_id, client_secret, site: client_url, token_url: "/connect/token")

        # get access token using client credentials grant
        response = client.client_credentials.get_token(scope: "user:read")

        @token = response.token
      end

      def to_s
        token
      end
    end
  end
end
