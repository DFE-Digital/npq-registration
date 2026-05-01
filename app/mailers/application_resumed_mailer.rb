class ApplicationResumedMailer < ApplicationMailer
  TEMPLATE_ID = "5c648930-42e0-4b4a-9fc0-73617a9d6bdd".freeze

  def application_resumed_mail(to:, full_name:, provider_name:, course_name:, ecf_id:)
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
