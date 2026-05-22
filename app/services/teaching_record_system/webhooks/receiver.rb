module TeachingRecordSystem
  module Webhooks
    class Receiver
      def self.call(webhook_params:)
        new(webhook_params:).call
      end

      def initialize(webhook_params:)
        self.webhook_params = webhook_params
      end

      def call
        webhook_message = ::GetAnIdentity::WebhookMessage
          .create_with(
            message_type: webhook_params[:message_type],
            sent_at: Time.zone.parse(webhook_params[:sent_at]),
            message: webhook_params[:message],
            status: :pending,
          )
          .find_or_initialize_by(message_id: webhook_params[:message_id])

        return true unless webhook_message.new_record?

        if webhook_message.save
          webhook_message.enqueue_processing_job
          return true
        end

        false
      end

    private

      attr_accessor :webhook_params
    end
  end
end
