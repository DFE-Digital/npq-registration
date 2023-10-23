module GetAnIdentityService
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
        return log_failure(message: "Secret Missing") if secret.blank?
        return log_failure(message: "Signature Blank") if signature.blank?
        return log_failure(message: "Request Body Empty") if request_body.blank?

        return true if signatures_match?

        log_failure(message: "Signature Mismatch", include_signatures: true)
      end

    private

      def log_failure(message:, include_signatures: false)
        Sentry.with_scope do |scope|
          if include_signatures
            scope.set_context("Signatures", {
              request_signature: signature,
              hashed_body_signature: expected_signature,
            })
          end

          Sentry.capture_message("GetAnIdentity webhook: #{message}")
        end

        false
      end

      def signatures_match?
        signature.casecmp(expected_signature).zero? # case insensitive comparison
      end

      def secret
        ENV["GET_AN_IDENTITY_WEBHOOK_SECRET"]
      end

      def expected_signature
        @expected_signature ||= OpenSSL::HMAC.hexdigest("SHA256", secret, request_body)
      end
    end
  end
end
