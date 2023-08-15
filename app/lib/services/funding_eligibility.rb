module Services
  class FundingEligibility
    include CourseHelper
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

    FUNDING_STATUS_CODE_DESCRIPTIONS = {
      FUNDED_ELIGIBILITY_RESULT => "funding_details.scholarship_eligibility",
      NOT_IN_ENGLAND => "funding_details.inside_catchment",
      EARLY_YEARS_OUTSIDE_CATCHMENT => "funding_details.inside_catchment",
      SCHOOL_OUTSIDE_CATCHMENT => "funding_details.inside_catchment",
      INELIGIBLE_INSTITUTION_TYPE => "funding_details.ineligible_setting",
      EARLY_YEARS_INVALID_NPQ => "funding_details.ineligible_setting",
      NOT_LEAD_MENTOR_COURSE => "funding_details.ineligible_setting",
      INELIGIBLE_ESTABLISHMENT_TYPE => "funding_details.no_Ofsted",
    }.freeze

    attr_reader :institution,
                :course,
                :trn,
                :approved_itt_provider,
                :lead_mentor,
                :employment_role,
                :get_an_identity_id,
                :lead_mentor_for_accredited_itt_provider

    def initialize(institution:,
                   course:,
                   inside_catchment:,
                   trn:,
                   get_an_identity_id:,
                   lead_mentor_for_accredited_itt_provider: false,
                   approved_itt_provider: false,
                   lead_mentor: false,
                   new_headteacher: false,
                   employment_role: nil)
      @institution = institution
      @course = course
      @inside_catchment = inside_catchment
      @new_headteacher = new_headteacher
      @approved_itt_provider = approved_itt_provider
      @lead_mentor = lead_mentor
      @get_an_identity_id = get_an_identity_id
      @trn = trn
      @employment_role = employment_role
      @lead_mentor_for_accredited_itt_provider = lead_mentor_for_accredited_itt_provider
    end

    def funded?
      funding_eligiblity_status_code == FUNDED_ELIGIBILITY_RESULT
    end

    def funding_eligiblity_status_code
      @funding_eligiblity_status_code ||= begin
        if approved_itt_provider && (!course.npqlpm? || (course.npqlpm? && lead_mentor_for_accredited_itt_provider && inside_catchment?))
          return lead_mentor_eligibility_status
        end

        return NOT_IN_ENGLAND unless inside_catchment?
        return NO_INSTITUTION if institution.nil?
        return PREVIOUSLY_FUNDED if previously_funded?
        return FUNDED_ELIGIBILITY_RESULT if eligible_urns.include?(institution.try(:urn))

        case institution.class.name
        when "School"
          return SCHOOL_OUTSIDE_CATCHMENT unless inside_catchment?
          unless institution.eligible_establishment? || (institution.eyl_funding_eligible? && course.eyl?)
            return INELIGIBLE_ESTABLISHMENT_TYPE
          end
          return NOT_NEW_HEADTEACHER_REQUESTING_EHCO if course.ehco? && !new_headteacher?

          FUNDED_ELIGIBILITY_RESULT
        when "PrivateChildcareProvider"
          return EARLY_YEARS_OUTSIDE_CATCHMENT unless inside_catchment?
          return EARLY_YEARS_INVALID_NPQ unless course.eyl?
          return NOT_ON_EARLY_YEARS_REGISTER unless institution.on_early_years_register?

          FUNDED_ELIGIBILITY_RESULT
        when "LocalAuthority"
          FUNDED_ELIGIBILITY_RESULT
        else
          INELIGIBLE_INSTITUTION_TYPE
        end
      end
    end

    def targeted_funding
      @targeted_funding ||= Services::Eligibility::TargetedFunding.new(
        institution:,
        course:,
        employment_role:,
      ).call
    end

    def previously_received_targeted_funding_support?
      # This makes an api call so limit usage
      ecf_api_funding_lookup["previously_received_targeted_funding_support"] == true
    end

    def ineligible_institution_type?
      [NO_INSTITUTION, INELIGIBLE_INSTITUTION_TYPE].include?(funding_eligiblity_status_code)
    end

    def get_description_for_funding_status
      status_code = funding_eligiblity_status_code
      return I18n.t("funding_details.not_eligible_ehco", course_name: localise_sentence_embedded_course_name(course)) if not_england_ehco? || not_eligible_england_ehco?
      return I18n.t("funding_details.previously_funded", course_name: localise_sentence_embedded_course_name(course)) if status_code == PREVIOUSLY_FUNDED

      I18n.t(FUNDING_STATUS_CODE_DESCRIPTIONS[status_code])
    end

  private

    def lead_mentor_eligibility_status
      if lead_mentor_course?
        return PREVIOUSLY_FUNDED if previously_funded?

        FUNDED_ELIGIBILITY_RESULT
      else
        NOT_LEAD_MENTOR_COURSE
      end
    end

    def inside_catchment?
      @inside_catchment
    end

    def new_headteacher?
      @new_headteacher
    end

    def lead_mentor_course?
      course.npqltd?
    end

    def eligible_urns
      %w[
        146816
        141030
        131867
        130416
        145003
        139730
        143704
        141940
        147756
        139363
        130468
        130457
        144753
        144886
        130503
        143689
        144511
        130452
        130548
        145002
        144463
        130458
        130411
        130422
        130746
        133608
        144887
        145230
        139433
        142673
        147477
        130580
        133545
        130504
      ]
    end

    def ecf_api_funding_lookup
      @ecf_api_funding_lookup = EcfApi::Npq::PreviousFunding.find_for(
        trn:,
        get_an_identity_id:,
        npq_course_identifier: course.identifier,
      )
    end

    def previously_funded?
      ecf_api_funding_lookup["previously_funded"] == true
    end

    def not_england_ehco?
      funding_eligiblity_status_code == NOT_IN_ENGLAND && course.ehco?
    end

    def not_eligible_england_ehco?
      inside_catchment? && course.ehco? unless funding_eligiblity_status_code == FUNDED_ELIGIBILITY_RESULT
    end
  end
end
