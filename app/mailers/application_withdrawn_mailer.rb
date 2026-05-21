class ApplicationWithdrawnMailer < ApplicationMailer
  TEMPLATE_ID = "06c2b9f3-f7cb-4877-b2c1-595e68b7a86e".freeze

  def application_withdrawn_mail(to:, full_name:, provider_name:, course_name:, ecf_id:)
    template_mail(TEMPLATE_ID,
                  to:,
                  personalisation: {
                    full_name:,
                    provider_name:,
                    course_name:,
                    ecf_id:,
                  })
  end
end
