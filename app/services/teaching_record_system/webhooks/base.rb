class TeachingRecordSystem::Webhooks::Base
  def self.call(webhook_message:)
    new(webhook_message:).call
  end

  def initialize(webhook_message:)
    self.webhook_message = webhook_message
  end

  def call
    return incorrect_format_failure unless correct_format?

    process! if user
    webhook_message.make_processed!
  end

private

  attr_accessor :webhook_message

  delegate :message, to: :webhook_message

  def user
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
