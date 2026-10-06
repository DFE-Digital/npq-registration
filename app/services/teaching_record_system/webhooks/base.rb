class TeachingRecordSystem::Webhooks::Base
  ADVISORY_LOCK = "lock-trs-webhooks".freeze

  def self.call(webhook_message:)
    new(webhook_message:).call
  end

  def initialize(webhook_message:)
    self.webhook_message = webhook_message
  end

  def call
    return incorrect_format_failure unless correct_format?

    ApplicationRecord.transaction do
      with_webhook_lock do
        process! if user
      end

      webhook_message.make_processed!
    end
  end

private

  attr_accessor :webhook_message

  delegate :message, to: :webhook_message

  def with_webhook_lock(&block)
    User.with_advisory_lock!(ADVISORY_LOCK, blocking: true, transaction: true, &block)
  end

  def user
    return if user_uid.blank?

    @user ||= User.find_by(uid: user_uid)
  end

  def incorrect_format_failure
    record_error("Invalid message format")
  end

  def record_error(message, send_to_sentry: true)
    webhook_message.update!(
      status: :failed,
      status_comment: message,
      processed_at: Time.zone.now,
    )
    Sentry.capture_message("[#{self.class::WEBHOOK_NAME}] #{message}") if send_to_sentry
  end
end
