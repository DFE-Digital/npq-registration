class ConfirmEmailMailer < ApplicationMailer
  TEMPLATE_ID = "8c9ef29c-8db2-44d2-84ff-ff062485a893".freeze

  def confirmation_code_mail(to:, code:)
    template_mail(TEMPLATE_ID,
                  to:,
                  personalisation: {
                    code:,
                  })
  end
end
