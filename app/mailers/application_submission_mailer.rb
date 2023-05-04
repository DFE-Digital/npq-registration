class ApplicationSubmissionMailer < ApplicationMailer
  def application_submitted_mail(_template_id, to:, full_name:, provider_name:, course_name:, amount:)
    template_mail("b8b53310-fa6f-4587-972a-f3f3c6e0892e",
                  to:,
                  personalisation: {
                    full_name:,
                    provider_name:,
                    course_name:,
                    amount:,
                  })
  end
end
