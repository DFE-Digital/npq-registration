module FundingHelper
    FUNDED_ELIGIBILITY_RESULT = :funded

    NO_INSTITUTION = :no_institution
    INELIGIBLE_ESTABLISHMENT_TYPE = :ineligible_establishment_type
    INELIGIBLE_INSTITUTION_TYPE = :ineligible_institution_type
    PREVIOUSLY_FUNDED = :previously_funded

    # EHCO
    NOT_NEW_HEADTEACHER_REQUESTING_EHCO = :not_new_headteacher_requesting_ehco

    # School
    SCHOOL_OUTSIDE_CATCHMENT = :school_outside_catchment

    # Early Years
    EARLY_YEARS_OUTSIDE_CATCHMENT = :early_years_outside_catchment
    NOT_ON_EARLY_YEARS_REGISTER = :not_on_early_years_register
    EARLY_YEARS_INVALID_NPQ = :early_years_invalid_npq

    # Lead Mentor
    NOT_LEAD_MENTOR_COURSE = :not_lead_mentor_course

    NOT_IN_ENGLAND = :not_in_england

    def scholarship_funding_eligibility(application)
        funding_eligibility = funding_eligibility_calculator(application)
        # return funding_eligibility.funding_eligiblity_status_code 
        
        if funding_eligibility.funded?
            I18n.t("funding_details.scholarship_eligibility")
        elsif funding_eligibility.funding_eligiblity_status_code == PREVIOUSLY_FUNDED
            I18n.t("funding_details.previously_funded")
        elsif [NOT_IN_ENGLAND, EARLY_YEARS_OUTSIDE_CATCHMENT, SCHOOL_OUTSIDE_CATCHMENT].include?(funding_eligibility.funding_eligiblity_status_code)
            I18n.t("funding_details.inside_catchment")
        elsif [INELIGIBLE_INSTITUTION_TYPE].include?(funding_eligibility.funding_eligiblity_status_code)
            I18n.t("funding_details.ineligible_setting")
        elsif funding_eligibility.funding_eligiblity_status_code == INELIGIBLE_ESTABLISHMENT_TYPE
            I18n.t("funding_details.ineligible_establishment")
        elsif scholarship_eligibility_in_review(application)
            I18n.t("funding_details.in_review")
        end
    end

    def scholarship_eligibility_in_review(application)
        application.work_setting == "other" && application.employment_type != "lead_mentor_for_accredited_itt_provider"
    end

    def targeted_support_funding(application)
        I18n.t("funding_details.targeted_funding_eligibility", funding_amount: funding_amount(application))
    end

    private

    def funding_eligibility_calculator(application)
        Services::FundingEligibility.new(
            course: application.course,
            institution:application.raw_application_data["institution_identifier"],
            approved_itt_provider: application.itt_provider,
            lead_mentor: application.lead_mentor,
            inside_catchment: application.teacher_catchment == "england",
            new_headteacher: application.headteacher_status,
            trn: application.raw_application_data["trn"],
            get_an_identity_id: current_user.get_an_identity_id,
          )
    end


    def funding_amount(application)
        application.targeted_delivery_funding_eligibility && application.tsf_primary_plus_eligibility ? 800 : 200
    end
end