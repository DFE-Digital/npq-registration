module API
  module V1
    module TeachingRecordSystem
      class WebhookMessagesController < ActionController::API
        def create
          # TODO: restrict to only accept requests with ce-type of "one_login_user.updated"
          #  currently we are receiving "alert.updated" events for testing purposes
          Linzer.verify!(request.rack_request) do |key_id|
            # TODO: cache this key for a day
            key(key_id)
          end
          ::TeachingRecordSystem::WebhookMessage.create!(status: :pending, raw: request.raw_post)
          head :ok
        rescue Linzer::Error => e
          Rails.logger.error("Failed to verify webhook message: #{e.message}")
          head :unauthorized
        end

      private

        def key(key_id)
          trs_jwks_endpoint = "#{ENV.fetch('TRS_API_URL')}/webhook-jwks"
          jwks = JWT::JWK::Set.new(JSON.parse(Net::HTTP.get(URI(trs_jwks_endpoint)))) # TODO: what about http failures? use Net::HTTP.get_response ?
          jwk = jwks.select { |key| key[:kid] == key_id }.first
          Linzer.new_ecdsa_p384_sha384_key(jwk.verify_key.to_pem, key_id) if jwk # TODO: test when jwk nil
        end
      end
    end
  end
end
