class ParticipantOutcomeFailedMailer < ApplicationMailer
  TEMPLATE_ID = "a0c2bf2e-262e-4879-8485-5357e3bfb2f3".freeze

  def failed_mail(to:, full_name:, provider_name:, course_name:, ecf_id:)
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
