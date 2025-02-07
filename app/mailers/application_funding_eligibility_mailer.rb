class ApplicationFundingEligibilityMailer < ApplicationMailer
  ELIGIBLE_FOR_FUNDING_TEMPLATE = "87b6e2f6-e2ef-4354-9c3d-876099918507".freeze

  def eligible_for_funding_mail(to:, full_name:, provider_name:, course_name:, ecf_id:)
    template_mail(ELIGIBLE_FOR_FUNDING_TEMPLATE,
                  to:,
                  personalisation: {
                    full_name:,
                    provider_name:,
                    course_name:,
                    ecf_id:,
                  })
  end
end
