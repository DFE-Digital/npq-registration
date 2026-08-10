module Questionnaires
  class IneligibleForFunding < Base
    class UnexpectedEligibilityStatusCode < StandardError; end

    NOT_ELIGIBLE_FOR_SCHOLARSHIP_FUNDING = "not_eligible_for_scholarship_funding".freeze
    UNFUNDED_COHORT = "unfunded_cohort".freeze
    NOT_IN_ENGLAND = "not_in_england".freeze
    EARLY_YEARS_NOT_APPLYING_FOR_NPQEY = "early_years/not_applying_for_NPQEY".freeze
    LEAD_MENTOR_NOT_APPLYING_FOR_NPQLTD = "lead_mentor/not_applying_for_NPQLTD".freeze
    EHCO_FUNDING_NOT_AVAILABLE = "ehco_funding_not_available".freeze

    # Already funded
    ALREADY_FUNDED_NOT_ELIGIBLE_SCHOLARSHIP_FUNDING = "already_funded/not_eligible_scholarship_funding".freeze

    attribute :version

    def previous_step
      return :teacher_catchment unless course

      if !wizard.query_store.inside_catchment? && wizard.query_store.teacher_catchment_specified?
        :teacher_catchment
      elsif works_in_another_setting? && employment_type_other?
        :choose_your_npq # TODO: test
      elsif course.ehco?
        if wizard.query_store.declared_previous_funding?
          :funding_history
        else
          :ehco_new_headteacher
        end
      elsif course.npqlpm?
        :maths_eligibility_teaching_for_mastery # TODO: test
      elsif course.npqs?
        :senco_in_role # TODO: test
      else
        :your_employer
      end
    end

    def next_step
      if course
        funding_your_npq_step
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
                               when FundingEligibility::INELIGIBLE_ESTABLISHMENT_TYPE
                                 return NOT_ELIGIBLE_FOR_SCHOLARSHIP_FUNDING
                               when FundingEligibility::PREVIOUSLY_FUNDED
                                 return ALREADY_FUNDED_NOT_ELIGIBLE_SCHOLARSHIP_FUNDING
                               when FundingEligibility::EARLY_YEARS_INVALID_NPQ
                                 return EARLY_YEARS_NOT_APPLYING_FOR_NPQEY # TODO: test
                               when FundingEligibility::INELIGIBLE_ESTABLISHMENT_NOT_A_PP50
                                 return "not_a_pp50_institution" # TODO: test
                               when FundingEligibility::NOT_ENTITLED_CHILDMINDER
                                 return "not_entitled_ey_institution"
                               when FundingEligibility::INELIGIBLE_INSTITUTION_TYPE
                                 return NOT_ELIGIBLE_FOR_SCHOLARSHIP_FUNDING # TODO: test
                               when FundingEligibility::UNFUNDED_COHORT
                                 return UNFUNDED_COHORT
                               when FundingEligibility::NOT_NEW_HEADTEACHER_REQUESTING_EHCO
                                 return EHCO_FUNDING_NOT_AVAILABLE
                               end
      raise UnexpectedEligibilityStatusCode, "Missing status code handling: #{funding_eligiblity_status_code}" # TODO: test
    end

    def funding_eligiblity_status_code
      @funding_eligiblity_status_code ||= funding_eligibility.funding_eligiblity_status_code
    end

    def funding_eligibility
      @funding_eligibility ||= FundingEligibility.new_from_query_store(
        course:,
        institution: query_store.institution,
        approved_itt_provider: approved_itt_provider?,
        inside_catchment: inside_catchment?,
        user_ecf_id: query_store.user_ecf_id,
        query_store: wizard.query_store,
      )
    end

    delegate :course,
             :lead_provider,
             :new_headteacher?,
             :inside_catchment?,
             :approved_itt_provider?,
             :lead_mentor_for_accredited_itt_provider?,
             :works_in_another_setting?,
             :employment_type_other?,
             to: :query_store
  end
end
