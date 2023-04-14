module GetAnIdentity
  class ProcessWebhookMessageJob < ApplicationJob
    queue_as :default

    def perform(webhook_message:)
      webhook_processor_klass = webhook_message.processor_klass

      if webhook_processor_klass.blank?
        webhook_message.update(
          status: :unhandled_message_type,
          status_comment: "No processor found for webhook message",
          processed_at: Time.zone.now,
        )
        return
      end

      webhook_processor_klass.call(webhook_message:)
    end
  end
end
