class ApplicationSubmissionMailer < ApplicationMailer
  def application_submitted_mail(to:, full_name:, provider_name:)
    template_mail("b8b53310-fa6f-4587-972a-f3f3c6e0892e",
                  to: to,
                  personalisation: {
                    full_name: full_name,
                    provider_name: provider_name,
                  })
  end
end
