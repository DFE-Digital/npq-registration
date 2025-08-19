module API
  module V1
    module GetAnIdentity
      class WebhookMessagesController < ActionController::API
        before_action :set_cache_headers
        before_action :verify_signature!, only: :create

        def create
          if GetAnIdentityService::Webhooks::Receiver.call(webhook_params:)
            head :ok
          else
            head :bad_request
          end
        end

      private

        def set_cache_headers
          no_store
        end

        def webhook_params
          params.permit(:notificationId, :timeUtc, :messageType, message: {})
        end

        def verify_signature!
          return if signature_valid?

          head :unauthorized
        end

        def signature_valid?
          signature = request.headers["X-Hub-Signature-256"]
          if signature.blank?
            Sentry.capture_message("GetAnIdentity webhook signature missing")
            return false
          end

          GetAnIdentityService::Webhooks::SignatureVerifier.call(
            request_body: request.raw_post,
            signature:,
          )
        end
      end
    end
  end
end
