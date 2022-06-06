class RegistrationOpenNotificationJob < ApplicationJob
  queue_as :default

  def perform(registration_interest:)
    RegistrationOpenNotificationMailer.notification_open_mail(to: registration_interest.email).deliver_now

    registration_interest.update!(notified: true)
  end
end
