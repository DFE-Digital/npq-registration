class RegistrationOpenNotificationJob < ApplicationJob
  queue_as :default

  def perform(registration_interest:)
    send_notification(registration_interest)

    registration_interest.update!(notified: true)
  end

  private

  def send_notification(registration_interest)
    return unless registration_interest.valid_email?

    RegistrationOpenNotificationMailer.notification_open_mail(to: registration_interest.email).deliver_now
  end
end
