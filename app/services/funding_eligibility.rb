class FundingEligibility
  include CourseHelper
  FUNDED_ELIGIBILITY_RESULT = :funded

  NO_INSTITUTION = :no_institution
  INELIGIBLE_ESTABLISHMENT_TYPE = :ineligible_establishment_type
  INELIGIBLE_ESTABLISHMENT_NOT_A_PP50 = :ineligible_establishment_not_a_pp50
  INELIGIBLE_INSTITUTION_TYPE = :ineligible_institution_type
  PREVIOUSLY_FUNDED = :previously_funded
  REFERRED_BY_RETURN_TO_TEACHING_ADVISER = :referred_by_return_to_teaching_adviser

  # EHCO
  NOT_NEW_HEADTEACHER_REQUESTING_EHCO = :not_new_headteacher_requesting_ehco

  # School
  SCHOOL_OUTSIDE_CATCHMENT = :school_outside_catchment

  # Early Years
  EARLY_YEARS_OUTSIDE_CATCHMENT = :early_years_outside_catchment
  NOT_ON_EARLY_YEARS_REGISTER = :not_on_early_years_register
  EARLY_YEARS_INVALID_NPQ = :early_years_invalid_npq
  NOT_ENTITLED_EY_INSTITUTION = :not_entitled_ey_institution
  NOT_ENTITLED_CHILDMINDER = :not_entitled_childminder

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
    INELIGIBLE_ESTABLISHMENT_NOT_A_PP50 => "funding_details.not_a_pp50",
    INELIGIBLE_ESTABLISHMENT_TYPE => "funding_details.ineligible_setting",
    NOT_ON_EARLY_YEARS_REGISTER => "funding_details.no_Ofsted",
    NOT_ENTITLED_EY_INSTITUTION => "funding_details.not_entitled_ey_institution",
    NOT_ENTITLED_CHILDMINDER => "funding_details.not_entitled_childminder",
  }.freeze

  attr_reader :institution,
              :course,
              :trn,
              :approved_itt_provider,
              :lead_mentor,
              :employment_role,
              :get_an_identity_id,
              :lead_mentor_for_accredited_itt_provider,
              :query_store

  def initialize(institution:,
                 course:,
                 inside_catchment:,
                 trn:,
                 get_an_identity_id:,
                 lead_mentor_for_accredited_itt_provider: false,
                 approved_itt_provider: false,
                 lead_mentor: false,
                 new_headteacher: false,
                 employment_role: nil,
                 query_store: nil)
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
    @query_store = query_store
  end

  def funded?
    funding_eligiblity_status_code == FUNDED_ELIGIBILITY_RESULT
  end

  def funding_eligiblity_status_code
    @funding_eligiblity_status_code ||= begin
      if approved_itt_provider && (!npqlpm_or_senco? || (npqlpm_or_senco? && lead_mentor_for_accredited_itt_provider && inside_catchment?))
        if lead_mentor_course?
          return PREVIOUSLY_FUNDED if previously_funded?

          return FUNDED_ELIGIBILITY_RESULT
        else
          return NOT_LEAD_MENTOR_COURSE
        end
      end

      return NOT_IN_ENGLAND unless inside_catchment?

      unless institution

        if query_store
          return INELIGIBLE_INSTITUTION_TYPE if course.ehco? && !query_store.new_headteacher?
          return REFERRED_BY_RETURN_TO_TEACHING_ADVISER if query_store.referred_by_return_to_teaching_adviser?
          return NO_INSTITUTION if query_store.local_authority_supply_teacher? || query_store.employment_type_local_authority_virtual_school?

          if query_store.employment_type_hospital_school? || query_store.young_offender_institution?
            return FUNDED_ELIGIBILITY_RESULT if course.npqlpm? || course.npqh? || course.npqs? || course.ehco?

            return NO_INSTITUTION
          end
        else
          return NO_INSTITUTION
        end
      end

      return PREVIOUSLY_FUNDED if previously_funded?

      case institution.class.name
      when "School"
        return NOT_ENTITLED_EY_INSTITUTION if course.eyl? && !institution.ey_eligible?
        return SCHOOL_OUTSIDE_CATCHMENT unless inside_catchment?
        return NOT_NEW_HEADTEACHER_REQUESTING_EHCO if course.ehco? && !new_headteacher?

        unless course.eyl?
          return FUNDED_ELIGIBILITY_RESULT if institution.local_authority_nursery_school? && course.la_nursery_approved?
          return FUNDED_ELIGIBILITY_RESULT if institution.la_disadvantaged_nursery?
          return INELIGIBLE_ESTABLISHMENT_NOT_A_PP50 if course.only_pp50? && !institution.pp50_institution?
          return INELIGIBLE_ESTABLISHMENT_TYPE unless institution.eligible_establishment?
        end

        FUNDED_ELIGIBILITY_RESULT
      when "PrivateChildcareProvider"
        return EARLY_YEARS_OUTSIDE_CATCHMENT unless inside_catchment?
        return NOT_ENTITLED_EY_INSTITUTION if course.eyl? && !institution.ey_eligible? && !childminder?
        return EARLY_YEARS_INVALID_NPQ unless course.eyl?
        return NOT_ON_EARLY_YEARS_REGISTER unless institution.on_early_years_register?
        return NOT_ENTITLED_CHILDMINDER if course.eyl? && childminder? && !institution.on_childminders_list?

        FUNDED_ELIGIBILITY_RESULT
      when "LocalAuthority"
        FUNDED_ELIGIBILITY_RESULT
      when "NilClass" # bit of stretch, but can be nil only when private ey setting is selected
        NOT_ON_EARLY_YEARS_REGISTER
      else
        INELIGIBLE_INSTITUTION_TYPE
      end
    end
  end

  def possible_funding_for_non_pp50_and_fe?
    course.only_pp50? && institution.is_a?(School)
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

    I18n.t(FUNDING_STATUS_CODE_DESCRIPTIONS[status_code]).html_safe
  end

private

  def inside_catchment?
    @inside_catchment
  end

  def new_headteacher?
    @new_headteacher
  end

  def lead_mentor_course?
    course.npqltd?
  end

  def npqlpm_or_senco?
    course.npqlpm? || course.npqs?
  end

  def ecf_api_funding_lookup
    @ecf_api_funding_lookup = External::EcfAPI::Npq::PreviousFunding.find_for(
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

  def childminder?
    query_store.childminder?
  end
end
