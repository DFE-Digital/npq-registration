class ConfirmEmailMailer < ApplicationMailer
  def confirmation_code_mail(to:, code:)
    template_mail("8c9ef29c-8db2-44d2-84ff-ff062485a893",
                  to:,
                  personalisation: {
                    code:,
                  })
  end
end
