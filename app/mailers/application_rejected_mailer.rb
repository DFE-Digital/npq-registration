class ApplicationRejectedMailer < ApplicationMailer
  TEMPLATE_ID = "76a5eb0d-4510-4e26-87ca-dc375e4bf972".freeze

  def application_rejected_mail(to:, full_name:, provider_name:, course_name:, ecf_id:)
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
