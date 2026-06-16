class ApplicationSubmissionMailer < ApplicationMailer
  TEMPLATE_ID = "b8b53310-fa6f-4587-972a-f3f3c6e0892e".freeze
  SPRING_2026_TEMPLATE_ID = "7ca4bae1-d5ac-4761-87ae-36bd790254bb".freeze

  def application_submitted_mail(template_id, to:, full_name:, provider_name:, course_name:, amount:, ecf_id:)
    template_mail(template_id || TEMPLATE_ID,
                  to:,
                  personalisation: {
                    full_name:,
                    provider_name:,
                    course_name:,
                    amount:,
                    ecf_id:,
                  })
  end
end
