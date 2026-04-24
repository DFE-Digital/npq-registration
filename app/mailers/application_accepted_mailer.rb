class ApplicationAcceptedMailer < ApplicationMailer
  TEMPLATE_ID = "3ccfcf63-f2bd-498b-a1d2-7814bb8bede8".freeze

  def application_accepted_mail(to:, full_name:, provider_name:, course_name:, ecf_id:)
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
