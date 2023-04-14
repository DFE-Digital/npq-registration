module Api
  module V1
    module GetAnIdentity
      class WebhookMessagesController < V1::BaseController
        before_action :verify_signature!, only: :create

        def create
          if Services::GetAnIdentity::Webhooks::Receiver.call(webhook_params:)
            head :ok
          else
            head :bad_request
          end
        end

      private

        def webhook_params
          params.permit(:notificationId, :timeUtc, :messageType, message: {})
        end

        def verify_signature!
          return if signature_valid?

          head :unauthorized
        end

        def signature_valid?
          signature = request.headers["X-Hub-Signature-256"]
          return false if signature.blank?

          Services::GetAnIdentity::Webhooks::SignatureVerifier.call(
            request_body: request.raw_post,
            signature:,
          )
        end
      end
    end
  end
end
