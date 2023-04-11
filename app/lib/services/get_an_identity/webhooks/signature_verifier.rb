module Services
  module GetAnIdentity
    module Webhooks
      class SignatureVerifier
        class << self
          def call(request_body:, signature:)
            new(request_body:, signature:).call
          end
        end

        attr_reader :request_body, :signature

        def initialize(request_body:, signature:)
          @request_body = request_body
          @signature = signature
        end

        def call
          if secret.blank?
            Sentry.capture_message("GetAnIdentity webhook secret missing")
            return false
          end

          if signature.blank?
            Sentry.capture_message("GetAnIdentity webhook signature missing")
            return false
          end

          if request_body.blank?
            Sentry.capture_message("GetAnIdentity webhook request body missing")
            return false
          end

          return true if signature == expected_signature

          Sentry.with_scope do |scope|
            scope.set_context("Signatures", {
              request_signature: signature,
              hashed_body_signature: expected_signature,
            })
            Sentry.capture_message("GetAnIdentity webhook signature mismatch")
          end

          false
        end

      private

        def secret
          ENV["GET_AN_IDENTITY_WEBHOOK_SECRET"]
        end

        def expected_signature
          OpenSSL::HMAC.hexdigest("SHA256", secret, request_body)
        end
      end
    end
  end
end
