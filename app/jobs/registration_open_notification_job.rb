class RegistrationOpenNotificationJob < ApplicationJob
  queue_as :default

  def perform(registration_interest:)
    send_notification(registration_interest)

    # rubocop:disable Rails/SkipsModelValidations
    # We actively want to skip validation here so that otherwise invalid
    # records are marked as notified
    registration_interest.update_attribute(:notified, true)
    # rubocop:enable Rails/SkipsModelValidations
  end

private

  def send_notification(registration_interest)
    return unless registration_interest.valid_email?

    RegistrationOpenNotificationMailer.notification_open_mail(to: registration_interest.email).deliver_now
  end
end
