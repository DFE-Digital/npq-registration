module GetAnIdentityService::Webhooks
  class JwksFetcher
    CACHE_DURATION = 1.day
    RETRY_MAX = 1
    RETRY_INTERVAL = 1.second

    def call(key_id)
      Rails.cache.fetch("teaching_record_system_jwks_#{key_id}", expires_in: CACHE_DURATION) do
        jwks = JWT::JWK::Set.new(JSON.parse(connection.get.body))
        jwk = jwks.select { |key| key[:kid] == key_id }.first
        Linzer.new_ecdsa_p384_sha384_key(jwk.verify_key.to_pem, key_id) if jwk
      end
    end

  private

    def connection
      @connection ||= Faraday.new(
        url: Rails.configuration.x.teaching_record_system.api_webhook_jwks_uri,
      ) do |faraday|
        retry_options = {
          max: RETRY_MAX,
          interval: RETRY_INTERVAL,
          exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Faraday::ServerError],
        }
        faraday.request :retry, retry_options
        faraday.response :raise_error
      end
    end
  end
end
