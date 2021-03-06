module Services
  class FundingEligibility
    FUNDED_ELIGIBILITY_RESULT = :funded

    NO_INSTITUTION = :no_institution
    INELIGIBLE_ESTABLISHMENT_TYPE = :ineligible_establishment_type
    INELIGIBLE_INSTITUTION_TYPE = :ineligible_institution_type
    PREVIOUSLY_FUNDED = :previously_funded

    # EHCO
    NOT_NEW_HEADTEACHER_REQUESTING_ASO = :not_new_headteacher_requesting_aso
    NOT_NEW_HEADTEACHER_REQUESTING_EHCO = :not_new_headteacher_requesting_ehco

    # School
    SCHOOL_OUTSIDE_CATCHMENT = :school_outside_catchment

    # Early Years
    EARLY_YEARS_OUTSIDE_CATCHMENT = :early_years_outside_catchment
    NOT_ON_EARLY_YEARS_REGISTER = :not_on_early_years_register
    EARLY_YEARS_INVALID_NPQ = :early_years_invalid_npq

    attr_reader :institution, :course

    def initialize(institution:, course:, inside_catchment:, trn:, new_headteacher: false)
      @institution = institution
      @course = course
      @inside_catchment = inside_catchment
      @new_headteacher = new_headteacher
      @trn = trn
    end

    def funded?
      funding_eligiblity_status_code == FUNDED_ELIGIBILITY_RESULT
    end

    def funding_eligiblity_status_code
      @funding_eligiblity_status_code ||= begin
        return NO_INSTITUTION if institution.nil?
        return PREVIOUSLY_FUNDED if previously_funded?
        return FUNDED_ELIGIBILITY_RESULT if eligible_urns.include?(institution.urn)

        case institution.class.name
        when "School"
          return SCHOOL_OUTSIDE_CATCHMENT unless inside_catchment?
          return INELIGIBLE_ESTABLISHMENT_TYPE unless eligible_establishment_type_codes.include?(institution.establishment_type_code)
          return NOT_NEW_HEADTEACHER_REQUESTING_ASO if course.aso? && !new_headteacher?
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

    def ineligible_institution_type?
      [NO_INSTITUTION, INELIGIBLE_INSTITUTION_TYPE].include?(funding_eligiblity_status_code)
    end

  private

    def inside_catchment?
      @inside_catchment
    end

    def new_headteacher?
      @new_headteacher
    end

    def eligible_establishment_type_codes
      %w[1 2 3 5 6 7 8 10 12 14 15 18 24 26 28 31 32 33 34 35 36 38 39 40 41 42 43 44 45 46].freeze
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

    def previously_funded?
      results = EcfApi::NpqFunding.with_params(npq_course_identifier: course.identifier).find(@trn)

      results["previously_funded"] == true
    end
  end
end
