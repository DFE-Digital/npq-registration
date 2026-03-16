module API
  module TeachingRecordSystem
    module V1
      class WebhookMessagesController < ActionController::API
        def create
          # TODO: restrict to only accept requests with ce-type of "one_login_user.updated"
          #  currently we are receiving "alert.updated" events for testing purposes
          Linzer.verify!(request.rack_request) do |key_id|
            ::GetAnIdentityService::Webhooks::JwksFetcher.new.call(key_id)
          end
          ::GetAnIdentity::WebhookMessage.create!(status: :pending,
                                                  message_id: request.headers["ce-id"],
                                                  message_type: request.headers["ce-type"],
                                                  message_source: request.headers["ce-source"],
                                                  message: JSON.parse(request.body),
                                                  raw: request.raw_post)
          head :ok
        rescue Linzer::Error => e
          Rails.logger.error("Failed to verify webhook message: #{e.message}")
          head :unauthorized
        end
      end
    end
  end
end
