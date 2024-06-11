module FundingHelper
  include Helpers::Institution
  def scholarship_funding_eligibility(application)
    funding_eligibility = funding_eligibility_calculator(application)

    return I18n.t("funding_details.no_Ofsted") if application.raw_application_data["has_ofsted_urn"] == "no" && !application.course.ehco?

    funding_eligibility.get_description_for_funding_status
  end

  def scholarship_eligibility_in_review?(application)
    return false if application.eligible_for_funding
    return false if !application.eligible_for_funding && application.funding_choice.present?
    return false if application.employment_type == "other"
    return false unless application.inside_catchment?
    return true if application.course.ehco? && new_headteacher?(application)

    application.work_setting == "other" && application.employment_type != "lead_mentor_for_accredited_itt_provider" && application.course.identifier != "npq-early-headship-coaching-offer"
  end

  def targeted_support_funding
    I18n.t("funding_details.targeted_funding_eligibility").html_safe
  end

private

  def funding_eligibility_calculator(application)
    FundingEligibility.new(
      course: application.course,
      institution: institution(source: application.raw_application_data["institution_identifier"], application:),
      approved_itt_provider: application.itt_provider.present?,
      lead_mentor: application.lead_mentor.present?,
      inside_catchment: application.teacher_catchment == "england",
      new_headteacher: new_headteacher?(application),
      trn: application.user.trn,
      get_an_identity_id: application.user.get_an_identity_id,
      query_store: query_store(application),
    )
  end

  def query_store(application)
    RegistrationQueryStore.new(store: application.raw_application_data)
  end

  def new_headteacher?(application)
    %w[yes_in_first_two_years yes_in_first_five_years yes_when_course_starts].include?(application.headteacher_status)
  end
end
