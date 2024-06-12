module Questionnaires
  class IneligibleForFunding < Base
    include Helpers::Institution

    NOT_ELIGIBLE_FOR_SCHOLARSHIP_FUNDING = "not_eligible_for_scholarship_funding".freeze
    NOT_IN_ENGLAND = "not_in_england".freeze
    EARLY_YEARS_OUTSIDE_CATCHMENT_OR_INELIGIBLE_ESTABLISHMENT = "early_years/outside_catchment_or_not_on_early_years_register".freeze
    EARLY_YEARS_NOT_APPLYING_FOR_NPQEY = "early_years/not_applying_for_NPQEY".freeze
    LEAD_MENTOR_NOT_APPLYING_FOR_NPQLTD = "lead_mentor/not_applying_for_NPQLTD".freeze

    # Already funded
    ALREADY_FUNDED_NOT_ELIGIBLE_SCHOLARSHIP_FUNDING = "already_funded/not_eligible_scholarship_funding".freeze
    ALREADY_FUNDED_NOT_ELIGIBLE_SCHOLARSHIP_FUNDING_NOT_TSF = "already_funded/not_eligible_scholarship_funding_not_tsf".freeze

    attr_accessor :version

    def next_step
      :funding_your_npq
    end

    def previous_step
      if works_in_other? && employment_type_other?
        :choose_your_npq
      elsif course.npqlpm?
        if wizard.query_store.maths_understanding?
          :maths_eligibility_teaching_for_mastery
        else
          :maths_understanding_of_approach
        end
      elsif course.npqs?
        if wizard.query_store.senco_in_role_status?
          :senco_start_date
        else
          :senco_in_role
        end
      else
        :choose_your_npq
      end
    end

    def ineligible_template
      @ineligible_template ||= case funding_eligiblity_status_code
                               when FundingEligibility::NOT_IN_ENGLAND
                                 return NOT_IN_ENGLAND
                               when FundingEligibility::NOT_LEAD_MENTOR_COURSE
                                 return LEAD_MENTOR_NOT_APPLYING_FOR_NPQLTD
                               when FundingEligibility::SCHOOL_OUTSIDE_CATCHMENT, FundingEligibility::INELIGIBLE_ESTABLISHMENT_TYPE
                                 return NOT_ELIGIBLE_FOR_SCHOLARSHIP_FUNDING
                               when FundingEligibility::PREVIOUSLY_FUNDED
                                 if tsf_elgible?
                                   return ALREADY_FUNDED_NOT_ELIGIBLE_SCHOLARSHIP_FUNDING
                                 else
                                   return ALREADY_FUNDED_NOT_ELIGIBLE_SCHOLARSHIP_FUNDING_NOT_TSF
                                 end
                               when FundingEligibility::EARLY_YEARS_OUTSIDE_CATCHMENT, FundingEligibility::NOT_ON_EARLY_YEARS_REGISTER
                                 return EARLY_YEARS_OUTSIDE_CATCHMENT_OR_INELIGIBLE_ESTABLISHMENT
                               when FundingEligibility::EARLY_YEARS_INVALID_NPQ
                                 return EARLY_YEARS_NOT_APPLYING_FOR_NPQEY
                               when FundingEligibility::NOT_ENTITLED_EY_INSTITUTION
                                 return "not_entitled_ey_institution"
                               when FundingEligibility::INELIGIBLE_ESTABLISHMENT_NOT_A_PP50
                                 return "not_a_pp50_institution"
                               when FundingEligibility::NOT_ENTITLED_CHILDMINDER
                                 return "not_a_eligible_childminder"
                               when FundingEligibility::NO_INSTITUTION
                                 return NOT_ELIGIBLE_FOR_SCHOLARSHIP_FUNDING
                               end

      raise "Missing status code handling: #{funding_eligiblity_status_code}"
    end

    def funding_eligiblity_status_code
      @funding_eligiblity_status_code ||= FundingEligibility.new(
        course:,
        institution:,
        approved_itt_provider: approved_itt_provider?,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
        trn: wizard.query_store.trn,
        get_an_identity_id: wizard.query_store.get_an_identity_id,
        lead_mentor_for_accredited_itt_provider: lead_mentor_for_accredited_itt_provider?,
        query_store: wizard.query_store,
      ).funding_eligiblity_status_code
    end

    def tsf_elgible?
      targeted_delivery_funding_eligibility? || tsf_primary_eligibility? || tsf_primary_plus_eligibility?
    end

    def funding_amount
      @funding_amount ||= targeted_delivery_funding_eligibility? && tsf_primary_plus_eligibility? ? 800 : 200
    end

    delegate :course,
             :targeted_delivery_funding_eligibility?,
             :tsf_primary_plus_eligibility?,
             :tsf_primary_eligibility?,
             :lead_provider,
             :new_headteacher?,
             :inside_catchment?,
             :approved_itt_provider?,
             :lead_mentor_for_accredited_itt_provider?,
             :works_in_other?,
             :employment_type_other?,
             to: :query_store
  end
end
