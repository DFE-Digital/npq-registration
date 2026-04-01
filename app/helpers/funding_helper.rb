module FundingHelper
  def scholarship_funding_eligibility(application)
    if application.raw_application_data["has_ofsted_urn"] == "no" && !application.course.ehco?
      return I18n.t("funding_details.no_ofsted")
    end

    key = FundingEligibility::FUNDING_STATUS_CODE_DESCRIPTIONS[application.funding_eligiblity_status_code&.to_sym]
    course_name = localise_sentence_embedded_course_name(application.course)

    sanitize I18n.t("funding_details.#{key}", course_name:) if key
  end

  def scholarship_eligibility_in_review?(application)
    return false if application.eligible_for_funding
    return false if !application.eligible_for_funding && application.funding_choice.present?
    return false if application.employment_type == "other"
    return false unless application.inside_catchment?
    return true if application.course.ehco? && new_headteacher?(application)
    return true if application.referred_by_return_to_teaching_adviser == "yes"

    application.work_setting == "another_setting" && application.employment_type != "lead_mentor_for_accredited_itt_provider" && application.course.identifier != "npq-early-headship-coaching-offer"
  end

  def targeted_support_funding
    sanitize I18n.t("funding_details.targeted_funding_eligibility")
  end
end
