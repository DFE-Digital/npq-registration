module GetAnIdentityService::Webhooks
  class SigningKeyFetcher
    CACHE_DURATION = 1.day
    RETRY_MAX = 1
    RETRY_INTERVAL = 1.second

    def call(key_id)
      jwks_response = Rails.cache.fetch("teaching_record_system_jwks", expires_in: CACHE_DURATION) do
        connection.get.body
      end
      jwks = JWT::JWK::Set.new(jwks_response)
      jwk = jwks.select { |key| key[:kid] == key_id }.first
      Linzer.new_ecdsa_p384_sha384_key(jwk.verify_key.to_pem, key_id) if jwk
    end

  private

    def connection
      @connection ||= Faraday.new(url: jwks_uri) do |faraday|
        retry_options = {
          max: RETRY_MAX,
          interval: RETRY_INTERVAL,
          exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Faraday::ServerError],
        }
        faraday.request :retry, retry_options
        faraday.response :json
        faraday.response :raise_error
      end
    end

    def jwks_uri
      "#{ENV.fetch("TRS_API_URL")}/webhook-jwks"
    end
  end
end
