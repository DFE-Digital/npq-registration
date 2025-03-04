class RegistrationOpenNotificationMailer < ApplicationMailer
  TEMPLATE_ID = "5b153309-7902-4da0-9438-3f54ed2fffec".freeze

  def notification_open_mail(to:)
    template_mail(TEMPLATE_ID, to:)
  end
end
