class ApplicationSubmissionMailer < ApplicationMailer
  def application_submitted_mail(template_id, to:, full_name:, provider_name:, course_name:, amount:)
    template_mail(template_id,
                  to:,
                  personalisation: {
                    full_name:,
                    provider_name:,
                    course_name:,
                    amount:,
                  })
  end
end
