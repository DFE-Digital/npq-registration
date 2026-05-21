module API
  module TeachingRecordSystem
    module V1
      class WebhookMessagesController < ActionController::API
        before_action :verify_request

        def create
          # TODO: restrict to only accept requests with ce-types of "one_login_user.updated", and "trn_request.completed"
          # ce-types documented here: https://github.com/DFE-Digital/teaching-record-system/blob/main/docs/api-designs/webhooks.md
          ::GetAnIdentity::WebhookMessage.create!(status: :pending,
                                                  message_id: request.headers["ce-id"],
                                                  message_type: request.headers["ce-type"],
                                                  message_source: request.headers["ce-source"],
                                                  sent_at: request.headers["ce-time"],
                                                  message: JSON.parse(request.body),
                                                  raw: request.raw_post)
          head :ok
        end

      private

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
