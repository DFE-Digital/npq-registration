module FundingHelper
  def scholarship_funding_eligibility(application)
    # This appears to be a work around for the funding status not recording the no ofsted outcome
    if application.raw_application_data["has_ofsted_urn"] == "no" && !application.course.ehco?
      return I18n.t("funding_details.no_ofsted") # FIXME: this appears to be recalculating funding outcome
    end

    key = FundingEligibility::FUNDING_STATUS_CODE_DESCRIPTIONS[application.funding_eligiblity_status_code&.to_sym]
    course_name = localise_sentence_embedded_course_name(application.course)

    sanitize I18n.t("funding_details.#{key}", course_name:) if key
  end

  def scholarship_funding_eligibility_status(application)
    if application.eligible_for_funding?
      :eligible
    elsif scholarship_eligibility_in_review?(application)
      :in_review # TODO: test
    else
      :not_eligible
    end
  end

  def scholarship_eligibility_in_review?(application)
    application.eligibility_in_review?
  end

  def targeted_support_funding
    sanitize I18n.t("funding_details.targeted_funding_eligibility") # TODO: test
  end
end
