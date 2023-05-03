module Forms
  class IneligibleForFunding < Base
    include Helpers::Institution

    NOT_ELIGIBLE_FOR_SCHOLARSHIP_FUNDING = "not_eligible_for_scholarship_funding".freeze
    NOT_IN_ENGLAND = "not_in_england".freeze
    EARLY_YEARS_OUTSIDE_CATCHMENT_OR_INELIGIBLE_ESTABLISHMENT = "early_years/outside_catchment_or_not_on_early_years_register".freeze
    EARLY_YEARS_NOT_APPLYING_FOR_NPQEY = "early_years/not_applying_for_NPQEY".freeze
    LEAD_MENTOR_NOT_APPLYING_FOR_NPQLTD = "lead_mentor/not_applying_for_NPQLTD".freeze

    # Already funded
    ALREADY_FUNDED_NOT_ELIGIBLE_SCHOLARSHIP_FUNDING = "already_funded/not_eligible_scholarship_funding".freeze
    ALREADY_FUNDED_NOT_ELGIBLE_EHCO_FUNDING = "already_funded/not_eligible_ehco_funding".freeze
    ALREADY_FUNDED_NOT_ELIGIBLE_SCHOLARSHIP_FUNDING_NOT_TSF = "already_funded/not_eligible_scholarship_funding_not_tsf".freeze

    attr_accessor :version

    def next_step
      :funding_your_npq
    end

    def previous_step
      :choose_your_npq
    end

    def after_save
      wizard.store["email_template"] = ineligible_template
    end

    def ineligible_template
      @ineligible_template ||= case funding_eligiblity_status_code
                               when Services::FundingEligibility::NOT_IN_ENGLAND
                                 return NOT_IN_ENGLAND
                               when Services::FundingEligibility::NOT_LEAD_MENTOR_COURSE
                                 return LEAD_MENTOR_NOT_APPLYING_FOR_NPQLTD
                               when Services::FundingEligibility::SCHOOL_OUTSIDE_CATCHMENT, Services::FundingEligibility::INELIGIBLE_ESTABLISHMENT_TYPE
                                 return NOT_ELIGIBLE_FOR_SCHOLARSHIP_FUNDING
                               when Services::FundingEligibility::PREVIOUSLY_FUNDED
                                 if tsf_elgible?
                                   return ALREADY_FUNDED_NOT_ELIGIBLE_SCHOLARSHIP_FUNDING
                                 else
                                   return ALREADY_FUNDED_NOT_ELIGIBLE_SCHOLARSHIP_FUNDING_NOT_TSF
                                 end
                               when Services::FundingEligibility::EARLY_YEARS_OUTSIDE_CATCHMENT, Services::FundingEligibility::NOT_ON_EARLY_YEARS_REGISTER
                                 return EARLY_YEARS_OUTSIDE_CATCHMENT_OR_INELIGIBLE_ESTABLISHMENT
                               when Services::FundingEligibility::EARLY_YEARS_INVALID_NPQ
                                 return EARLY_YEARS_NOT_APPLYING_FOR_NPQEY
                               when Services::FundingEligibility::NO_INSTITUTION
                                 if query_store.works_in_school?
                                   return NOT_ELIGIBLE_FOR_SCHOLARSHIP_FUNDING
                                 else
                                   return EARLY_YEARS_OUTSIDE_CATCHMENT_OR_INELIGIBLE_ESTABLISHMENT
                                 end
                               end

      raise "Missing status code handling: #{funding_eligiblity_status_code}"
    end

    def funding_eligiblity_status_code
      wizard.query_store.funding_eligiblity_status_code
    end

    def tsf_elgible?
      wizard.query_store.targeted_delivery_funding_eligibility? ||
        wizard.query_store.tsf_primary_eligibility? ||
        wizard.query_store.tsf_primary_plus_eligibility?
    end

    delegate :course, :new_headteacher?, :inside_catchment?, :approved_itt_provider?, to: :query_store
  end
end
