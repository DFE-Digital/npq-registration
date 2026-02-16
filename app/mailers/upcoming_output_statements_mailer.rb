class UpcomingOutputStatementsMailer < ApplicationMailer
  TEMPLATE_ID = "769a5a54-124c-4e16-85bf-ff70012953d4".freeze

  def email_upcoming_output_statements_mail(to:, this_months_statements:, next_months_statements:)
    template_mail(TEMPLATE_ID,
                  to:,
                  personalisation: {
                    this_months_statements:,
                    next_months_statements:,
                  })
  end
end
