class EmailUpdatesConfirmationMailer < ApplicationMailer
  def email_updates_confirmation_mail(to:, service_link:, unsubscribe_link:)
    template_mail("9cce029e-1d43-40ee-8664-2657fc22b1eb",
                  to:,
                  personalisation: {
                    unsubscribe_link:,
                    service_link:,
                  })
  end
end
