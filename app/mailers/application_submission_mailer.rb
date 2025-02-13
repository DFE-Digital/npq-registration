class ApplicationSubmissionMailer < ApplicationMailer
  TEMPLATE_ID = "b8b53310-fa6f-4587-972a-f3f3c6e0892e".freeze

  def application_submitted_mail(_template_id, to:, full_name:, provider_name:, course_name:, amount:, ecf_id:)
    template_mail(TEMPLATE_ID,
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
