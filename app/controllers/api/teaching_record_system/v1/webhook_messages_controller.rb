module API
  module TeachingRecordSystem
    module V1
      class WebhookMessagesController < ActionController::API
        before_action :verify_request

        def create
          # ce-types will be documented here: https://github.com/DFE-Digital/teaching-record-system/blob/main/docs/api-designs/webhooks.md
          if ::TeachingRecordSystem::Webhooks::Receiver.call(webhook_params:)
            head :ok
          else
            head :bad_request
          end
        end

      private

        def webhook_params
          {
            message_id: request.headers["ce-id"],
            message_type: request.headers["ce-type"],
            message_source: request.headers["ce-source"],
            sent_at: request.headers["ce-time"],
            message: JSON.parse(request.raw_post),
          }
        end

        def verify_request
          Linzer.verify!(request.rack_request) do |key_id|
            ::GetAnIdentityService::Webhooks::SigningKeyFetcher.new.call(key_id)
          end
        rescue Linzer::Error => e
          Rails.logger.error("Failed to verify webhook message: #{e.message}")
          head :unauthorized
        end
      end
    end
  end
end
