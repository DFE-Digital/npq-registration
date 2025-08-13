class FundingEligibility
  include CourseHelper

  FUNDED_ELIGIBILITY_RESULT = :funded
  SUBJECT_TO_REVIEW = :subject_to_review

  NO_INSTITUTION = :no_institution
  INELIGIBLE_ESTABLISHMENT_TYPE = :ineligible_establishment_type
  INELIGIBLE_ESTABLISHMENT_NOT_A_PP50 = :ineligible_establishment_not_a_pp50
  INELIGIBLE_INSTITUTION_TYPE = :ineligible_institution_type
  PREVIOUSLY_FUNDED = :previously_funded
  REFERRED_BY_RETURN_TO_TEACHING_ADVISER = :referred_by_return_to_teaching_adviser

  # EHCO
  NOT_NEW_HEADTEACHER_REQUESTING_EHCO = :not_new_headteacher_requesting_ehco

  # Early Years
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
    INELIGIBLE_INSTITUTION_TYPE => "funding_details.ineligible_setting",
    EARLY_YEARS_INVALID_NPQ => "funding_details.ineligible_setting",
    NOT_LEAD_MENTOR_COURSE => "funding_details.ineligible_setting",
    INELIGIBLE_ESTABLISHMENT_NOT_A_PP50 => "funding_details.not_a_pp50",
    INELIGIBLE_ESTABLISHMENT_TYPE => "funding_details.ineligible_setting",
    NOT_ON_EARLY_YEARS_REGISTER => "funding_details.no_Ofsted",
    NOT_ENTITLED_EY_INSTITUTION => "funding_details.not_entitled_ey_institution",
    NOT_ENTITLED_CHILDMINDER => "funding_details.not_entitled_childminder",
    NOT_NEW_HEADTEACHER_REQUESTING_EHCO => "funding_details.not_eligible_ehco",
    PREVIOUSLY_FUNDED => "funding_details.previously_funded",
  }.freeze

  attr_reader :institution,
              :course,
              :trn,
              :approved_itt_provider,
              :lead_mentor,
              :get_an_identity_id,
              :lead_mentor_for_accredited_itt_provider,
              :query_store

  delegate :childminder?,
           :referred_by_return_to_teaching_adviser?,
           :work_setting,
           to: :query_store

  delegate :eligibility_data, to: :class, private: true
  delegate :rise_school?, to: :eligibility_data, private: true

  class << self
    def eligibility_data
      @eligibility_data ||= FundingEligibilityData.new
    end
  end

  def initialize(institution:,
                 course:,
                 inside_catchment:,
                 trn:,
                 get_an_identity_id:,
                 lead_mentor_for_accredited_itt_provider: false,
                 approved_itt_provider: false,
                 lead_mentor: false,
                 new_headteacher: false,
                 query_store: nil)
    @institution = institution
    @course = course
    @inside_catchment = inside_catchment
    @new_headteacher = new_headteacher
    @approved_itt_provider = approved_itt_provider
    @lead_mentor = lead_mentor
    @get_an_identity_id = get_an_identity_id
    @trn = trn
    @lead_mentor_for_accredited_itt_provider = lead_mentor_for_accredited_itt_provider
    @query_store = query_store
  end

  def funded?
    funding_eligiblity_status_code == FUNDED_ELIGIBILITY_RESULT
  end

  def subject_to_review?
    funding_eligiblity_status_code.in? [SUBJECT_TO_REVIEW, REFERRED_BY_RETURN_TO_TEACHING_ADVISER]
  end

  def funding_eligiblity_status_code
    @funding_eligiblity_status_code ||= begin
      return NOT_IN_ENGLAND unless @inside_catchment
      return PREVIOUSLY_FUNDED if previously_funded?

      if course.ehco?
        return FUNDED_ELIGIBILITY_RESULT if query_store.new_headteacher?

        return NOT_NEW_HEADTEACHER_REQUESTING_EHCO
      end

      case query_store.work_setting
      when *Questionnaires::WorkSetting::CHILDCARE_SETTINGS then childcare_policy
      when *Questionnaires::WorkSetting::SCHOOL_SETTINGS then school_policy
      when *Questionnaires::WorkSetting::ANOTHER_SETTING_SETTINGS then another_setting_policy
      when *Questionnaires::WorkSetting::OTHER_SETTINGS then other_settings_policy
      else INELIGIBLE_ESTABLISHMENT_TYPE
      end
    end
  end

  def get_description_for_funding_status
    key = FUNDING_STATUS_CODE_DESCRIPTIONS.fetch(funding_eligiblity_status_code)
    course_name = localise_sentence_embedded_course_name(course)

    I18n.t(key, course_name:).html_safe if key
  end

private

  def childcare_policy
    if institution.try(:local_authority_nursery_school?)
      return EARLY_YEARS_INVALID_NPQ unless course.la_nursery_approved?
      return INELIGIBLE_ESTABLISHMENT_TYPE unless institution.la_disadvantaged_nursery?

      return FUNDED_ELIGIBILITY_RESULT
    end

    if query_store.childminder?
      if course.eyl?
        return FUNDED_ELIGIBILITY_RESULT if institution.on_childminders_list?

        return NOT_ENTITLED_CHILDMINDER
      end

      return EARLY_YEARS_INVALID_NPQ
    end

    if course.eyl?
      return FUNDED_ELIGIBILITY_RESULT if institution.eyl_disadvantaged?

      return NOT_ENTITLED_EY_INSTITUTION
    end

    EARLY_YEARS_INVALID_NPQ
  end

  def school_policy
    return INELIGIBLE_ESTABLISHMENT_TYPE unless institution.eligible_establishment?

    if course.only_pp50?
      return FUNDED_ELIGIBILITY_RESULT if institution.pp50?(work_setting)

      return INELIGIBLE_ESTABLISHMENT_NOT_A_PP50
    end

    FUNDED_ELIGIBILITY_RESULT
  end

  def another_setting_policy
    if query_store.employment_type == "lead_mentor_for_accredited_itt_provider"
      if course.npqltd?
        return FUNDED_ELIGIBILITY_RESULT if approved_itt_provider

        return INELIGIBLE_ESTABLISHMENT_TYPE
      end

      return NOT_LEAD_MENTOR_COURSE
    end

    eligible_employment_types = %w[
      local_authority_virtual_school
      hospital_school
      young_offender_institution
      local_authority_supply_teacher
    ]

    eligible_course_identifiers = %w[
      npq-senco
      npq-headship
    ]

    if query_store.employment_type.in?(eligible_employment_types) && course.identifier.in?(eligible_course_identifiers)
      SUBJECT_TO_REVIEW
    else
      INELIGIBLE_ESTABLISHMENT_TYPE
    end
  end

  def other_settings_policy
    if referred_by_return_to_teaching_adviser?
      REFERRED_BY_RETURN_TO_TEACHING_ADVISER
    else
      INELIGIBLE_ESTABLISHMENT_TYPE
    end
  end

  def users
    get_an_identity_id_users.or(trn_users).distinct
  end

  def get_an_identity_id_users
    return User.none if get_an_identity_id.blank?

    User.with_get_an_identity_id.where(uid: get_an_identity_id)
  end

  def trn_users
    return User.none if trn.blank?

    User.where(trn:)
  end

  def previously_funded?
    accepted_applications.any?
  end

  def accepted_applications
    @accepted_applications ||= begin
      application_ids = users.flat_map do |user|
        user.applications
            .where(course: course.rebranded_alternative_courses)
            .accepted
            .eligible_for_funding
            .where(funded_place: [nil, true])
            .pluck(:id)
      end

      Application.where(id: application_ids)
    end
  end
end
