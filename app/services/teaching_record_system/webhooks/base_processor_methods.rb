module TeachingRecordSystem::Webhooks::BaseProcessorMethods
private

  def user
    @user ||= User.find_by(uid: user_uid)
  end

  def incorrect_format_failure
    record_error("Invalid message format")
  end

  def no_user_found_failure
    record_error("No user found with uid: #{user_uid}")
  end

  def record_error(message)
    webhook_message.update!(
      status: :failed,
      status_comment: message,
      processed_at: Time.zone.now,
    )
    Sentry.capture_message("[#{webhook_name}] #{message}")
  end
end
