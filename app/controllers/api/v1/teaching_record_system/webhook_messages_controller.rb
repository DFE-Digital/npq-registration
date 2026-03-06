module API
  module V1
    module TeachingRecordSystem
      class WebhookMessagesController < ActionController::API
        def create
          # headers = {
          #   "signature-input" => request.headers["signature-input"],
          #   "signature" => request.headers["signature"],
          # }
          # message = Linzer::Message.new(request.rack_request)
          # signature = Linzer::Signature.build(headers)
          # result = Linzer.verify(key("key1"), message, signature)
          raw = {
            "signature-input" => request.headers["signature-input"],
            "signature" => request.headers["signature"],
            "RAW_POST_DATA" => request.raw_post,
            "Content-Digest" => request.headers["Content-Digest"],
            "ce-id" => request.headers["ce-id"],
            "ce-source" => request.headers["ce-source"],
            "ce-type" => request.headers["ce-type"],
            "ce-time" => request.headers["ce-time"],
          }
          result = Linzer.verify!(request.rack_request) do |key_id|
            key(key_id)
          end
          status = result ? :pending : :unauthorized
          ::TeachingRecordSystem::WebhookMessage.create!(status:, raw:)
          head :ok
        rescue Linzer::Error => e # TODO: temporary until verification code works. remove when verification code works
          raw = {
            "signature-input" => request.headers["signature-input"],
            "signature" => request.headers["signature"],
            "RAW_POST_DATA" => request.raw_post,
          }
          ::TeachingRecordSystem::WebhookMessage.create!(status: :failed, status_comment: e.message, raw:)
          head :unauthorized
        end

      private

        def key(key_id)
          trs_jwks_endpoint = "#{ENV.fetch('TRS_API_URL')}/webhook-jwks"
          # keys = JSON.parse(Net::HTTP.get(URI(trs_jwks_endpoint)))["keys"] # TODO: what about http failures? use Net::HTTP.get_response ?
          # keys.find { |key| key["kid"] == key_id }
          jwks = JWT::JWK::Set.new(JSON.parse(Net::HTTP.get(URI(trs_jwks_endpoint)))) # TODO: what about http failures? use Net::HTTP.get_response ?
          jwk = jwks.select { |key| key[:kid] == key_id }.first
          Linzer.new_ecdsa_p384_sha384_key(jwk.verify_key.to_pem, key_id) if jwk # TODO: test when jwk nil
        end
      end
    end
  end
end
