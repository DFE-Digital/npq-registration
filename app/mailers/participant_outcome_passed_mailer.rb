class ParticipantOutcomePassedMailer < ApplicationMailer
  TEMPLATE_ID = "cd7f52db-1c61-4774-85db-ebedb8a77abf".freeze

  def passed_mail(to:, full_name:, provider_name:, course_name:, ecf_id:)
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
