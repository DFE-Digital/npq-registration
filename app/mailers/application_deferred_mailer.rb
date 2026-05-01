class ApplicationDeferredMailer < ApplicationMailer
  TEMPLATE_ID = "6e29f6f2-5c9d-4106-baa7-7fd9aeed63d6".freeze

  def application_deferred_mail(to:, full_name:, provider_name:, course_name:, ecf_id:)
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
