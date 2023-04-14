class GetAnIdentity::WebhookMessage < ApplicationRecord
  enum status: {
    pending: "pending",
    processing: "processing",
    processed: "processed",
    failed: "failed",
    unhandled_message_type: "unhandled_message_type",
  }

  def processor_klass
    nil # No handlers are implemented yet
  end
end
