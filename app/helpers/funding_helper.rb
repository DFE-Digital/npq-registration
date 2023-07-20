module FundingHelper
  def scholarship_funding_eligibility(application)
    funding_eligibility = funding_eligibility_calculator(application)

    return I18n.t("funding_details.in_review") if scholarship_eligibility_in_review(application)

    eligibility_message = funding_eligibility.get_description_for_funding_status
    return I18n.t(eligibility_message) if eligibility_message
  end

  def scholarship_eligibility_in_review(application)
    application.work_setting == "other" && application.employment_type != "lead_mentor_for_accredited_itt_provider"
  end

  def targeted_support_funding(application)
    funding_amount = application.targeted_delivery_funding_eligibility && application.tsf_primary_plus_eligibility ? 800 : 200
    I18n.t("funding_details.targeted_funding_eligibility", funding_amount:)
  end

private

  def funding_eligibility_calculator(application)
    Services::FundingEligibility.new(
      course: application.course,
      institution: application.raw_application_data["institution_identifier"],
      approved_itt_provider: application.itt_provider.present?,
      lead_mentor: application.lead_mentor.present?,
      inside_catchment: application.teacher_catchment == "england",
      new_headteacher: application.headteacher_status == true,
      trn: current_user.trn,
      get_an_identity_id: current_user.get_an_identity_id,
    )
  end
end
