module GetAnIdentity
  module Webhooks
    class Receiver
      class << self
        def call(webhook_params:)
          new(webhook_params:).call
        end
      end

      def initialize(webhook_params:)
        self.webhook_params = webhook_params
      end

      def call
        return existing_webhook_message if existing_webhook_message.present?

        if new_webhook.save
          new_webhook.enqueue_processing_job
          true
        else
          false
        end
      end

    private

      attr_accessor :webhook_params

      def message_id
        webhook_params["notificationId"]
      end

      def message_type
        webhook_params["messageType"]
      end

      def message
        webhook_params["message"]
      end

      def sent_at
        raw_timestamp = webhook_params["timeUtc"]
        return if raw_timestamp.blank?

        Time.zone.parse(raw_timestamp)
      end

      def existing_webhook_message
        @existing_webhook_message ||= ::GetAnIdentity::WebhookMessage.find_by(message_id:)
      end

      def new_webhook
        @new_webhook ||= ::GetAnIdentity::WebhookMessage.new(
          message_id:,
          message_type:,
          message:,
          sent_at:,
          raw: webhook_params,
        )
      end
    end
  end
end
