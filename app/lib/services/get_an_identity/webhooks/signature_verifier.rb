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
          return false if signature.blank?
          return false if request_body.blank?

          signature == expected_signature
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
