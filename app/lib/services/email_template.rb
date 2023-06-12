class Services::EmailTemplate
  def self.call(data:)
    new(data:).call
  end

  attr_reader :data

  def initialize(data:)
    @data = data.with_indifferent_access
  end

  def call
    email_key
  end

private

  def email_key
    return :itt_leader_wrong_course if not_lead_mentor_course?
    return :not_england_wrong_catchment if not_in_england?

    # EHCO outcomes
    if course.ehco?
      return :already_funded_not_elgible_ehco_funding if previously_funded?
      return :ehco_scholarship_funding if eligible_for_funding?

      return :not_eligible_ehco_funding
    end

    if eligible_for_funding?
      return :eligible_scholarship_funding if targeted_delivery_funding_eligibility?

      return :eligible_scholarship_funding_not_tsf
    end

    if previously_funded?
      return :not_eligible_scholarship_funding if targeted_delivery_funding_eligibility?

      return :already_funded_not_eligible_scholarship_funding_not_tsf
    end

    if ofsted_register? || course.eyl?
      # Early years leadership NPQ outcomes
      return :not_npqeyl_on_ofsted_register if !course.eyl? && ofsted_register?
      return :not_on_ofsted_register if !ofsted_register? && course.eyl?
    end

    return :not_eligible_scholarship_funding_not_tsf if !eligible_for_funding? && !targeted_delivery_funding_eligibility?

    # Should not get called but left here as edge case if default ever needed
    :default
  end

  def ofsted_register?
    data["has_ofsted_urn"] == "yes"
  end

  def previously_funded?
    funding_eligiblity_status_code == Services::FundingEligibility::PREVIOUSLY_FUNDED
  end

  def not_in_england?
    funding_eligiblity_status_code == Services::FundingEligibility::NOT_IN_ENGLAND
  end

  def eligible_for_funding?
    funding_eligiblity_status_code == Services::FundingEligibility::FUNDED_ELIGIBILITY_RESULT
  end

  def not_lead_mentor_course?
    funding_eligiblity_status_code == Services::FundingEligibility::NOT_LEAD_MENTOR_COURSE
  end

  def course
    Course.find_by(identifier: data["course_identifier"])
  end

  def funding_eligiblity_status_code
    data["funding_eligiblity_status_code"]
  end

  def targeted_delivery_funding_eligibility?
    data["targeted_delivery_funding_eligibility"]
  end
end
