module GetAnIdentity
  class ProcessWebhookMessageJob < ApplicationJob
    class UnknownMessageTypeError < StandardError; end

    queue_as :default

    def perform(webhook_message:)
      webhook_message.update!(status: :processing)

      webhook_processor_klass = webhook_message.processor_klass

      if webhook_processor_klass.present?
        webhook_processor_klass.call(webhook_message:)
      elsif webhook_message.ignored_message_type?
        webhook_message.update!(
          status: :unhandled_message_type,
          status_comment: "No processor found for webhook message",
          processed_at: Time.zone.now,
        )
      else
        raise UnknownMessageTypeError, "No processor found for webhook message type: #{webhook_message.message_type}"
      end
    end
  end
end
