class WebhookMessage < ApplicationRecord
  self.table_name = "get_an_identity_webhook_messages"

  enum :status, {
    pending: "pending",
    processing: "processing",
    processed: "processed",
    failed: "failed",
    unhandled_message_type: "unhandled_message_type",
  }, suffix: true

  IGNORED_MESSAGE_TYPES = %w[].freeze

  def ignored_message_type?
    IGNORED_MESSAGE_TYPES.include?(message_type)
  end

  def processor_klass
    case message_type
    when "one_login_user.updated"
      TeachingRecordSystem::Webhooks::UserUpdatedProcessor
    when "trn_request.completed"
      TeachingRecordSystem::Webhooks::TrnRequestCompletedProcessor
    when "person.deactivated"
      TeachingRecordSystem::Webhooks::PersonDeactivatedProcessor
    end
  end

  def enqueue_processing_job
    ::TeachingRecordSystem::ProcessWebhookMessageJob.perform_later(webhook_message: self)
  end

  def retryable?
    failed_status? || unhandled_message_type_status?
  end

  def make_processed!
    update!(status: :processed, processed_at: Time.zone.now)
  end
end
