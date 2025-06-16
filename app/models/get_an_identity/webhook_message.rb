class GetAnIdentity::WebhookMessage < ApplicationRecord
  enum :status, {
    pending: "pending",
    processing: "processing",
    processed: "processed",
    failed: "failed",
    unhandled_message_type: "unhandled_message_type",
  }, suffix: true

  def processor_klass
    case message_type
    when "UserUpdated"
      GetAnIdentityService::Webhooks::UserUpdatedProcessor
    end
  end

  def decorated_message
    case message_type
    when "UserUpdated"
      GetAnIdentity::WebhookMessages::UserUpdatedDecorator.new(self)
    end
  end

  def enqueue_processing_job
    ::GetAnIdentity::ProcessWebhookMessageJob.perform_later(webhook_message: self)
  end

  def retryable?
    failed_status? || unhandled_message_type_status?
  end

  def make_processed!
    update!(status: :processed, processed_at: Time.zone.now)
  end
end
