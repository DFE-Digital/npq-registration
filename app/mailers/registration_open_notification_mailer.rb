class RegistrationOpenNotificationMailer < ApplicationMailer
  def notification_open_mail(to:)
    template_mail("5b153309-7902-4da0-9438-3f54ed2fffec", to:)
  end
end
