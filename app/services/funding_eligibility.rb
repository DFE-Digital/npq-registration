class FundingEligibility
  class MissingMandatoryInstitution < StandardError; end

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
    REFERRED_BY_RETURN_TO_TEACHING_ADVISER => "funding_details.subject_to_review",
    SUBJECT_TO_REVIEW => "funding_details.subject_to_review",
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
           :employment_type,
           :lead_mentor_for_accredited_itt_provider?,
           :new_headteacher?,
           :referred_by_return_to_teaching_adviser?,
           :work_setting,
           to: :query_store

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

  def previously_funded?
    accepted_applications.any?
  end

  def funding_eligiblity_status_code
    @funding_eligiblity_status_code ||= begin
      return NOT_IN_ENGLAND unless @inside_catchment
      return PREVIOUSLY_FUNDED if previously_funded?

      eligible_echo_new_headteacher ||
        eligible_itt_provider ||
        review_eligibility_referred_by_return_to_teaching_adviser ||
        eligible_rise ||
        eligible_not_pp50_course ||
        eligible_la_disadvantaged_nursery ||
        eligible_childminder ||
        eligible_disadvantaged_ey ||
        not_eligible_nursery_not_eyl ||
        eligible_pp50 ||
        INELIGIBLE_ESTABLISHMENT_TYPE
    end
  end

  # 1
  def eligible_echo_new_headteacher
    if course.ehco?
      return FUNDED_ELIGIBILITY_RESULT if new_headteacher?

      NOT_NEW_HEADTEACHER_REQUESTING_EHCO
    end
  end

  def review_eligibility_referred_by_return_to_teaching_adviser
    if work_setting.in?(Questionnaires::WorkSetting::OTHER_SETTINGS)
      if referred_by_return_to_teaching_adviser?
        REFERRED_BY_RETURN_TO_TEACHING_ADVISER
      else
        INELIGIBLE_ESTABLISHMENT_TYPE
      end
    end
  end

  # 8
  def eligible_rise
    if work_setting.in?(Questionnaires::WorkSetting::SCHOOL_SETTINGS) && mandatory_institution.rise?
      FUNDED_ELIGIBILITY_RESULT
    end
  end

  # 7
  def eligible_not_pp50_course
    if !course.only_pp50? && work_setting.in?(Questionnaires::WorkSetting::SCHOOL_SETTINGS)
      return FUNDED_ELIGIBILITY_RESULT if mandatory_institution.eligible_establishment?

      INELIGIBLE_ESTABLISHMENT_TYPE
    end
  end

  # 2
  def eligible_la_disadvantaged_nursery
    if institution.try(:local_authority_nursery_school?)
      return EARLY_YEARS_INVALID_NPQ unless course.identifier.in?(%w[npq-senco npq-headship npq-early-years-leadership])

      FUNDED_ELIGIBILITY_RESULT if institution.la_disadvantaged_nursery?
    end
  end

  # 3
  def eligible_childminder
    if course.eyl? &&
        work_setting.in?(Questionnaires::WorkSetting::CHILDCARE_SETTINGS) &&
        childminder?
      if mandatory_institution.on_childminders_list?
        FUNDED_ELIGIBILITY_RESULT
      else
        NOT_ENTITLED_CHILDMINDER
      end
    end
  end

  # 4
  def eligible_disadvantaged_ey
    if course.eyl? &&
        work_setting.in?(Questionnaires::WorkSetting::CHILDCARE_SETTINGS) &&
        !institution.try(:local_authority_nursery_school?)
      return FUNDED_ELIGIBILITY_RESULT if !childminder? && mandatory_institution.eyl_disadvantaged?

      NOT_ENTITLED_EY_INSTITUTION
    end
  end

  def not_eligible_nursery_not_eyl
    if work_setting.in?(Questionnaires::WorkSetting::CHILDCARE_SETTINGS) &&
        !institution.try(:local_authority_nursery_school?) &&
        !course.eyl?

      EARLY_YEARS_INVALID_NPQ
    end
  end

  # 5 & 6
  def eligible_pp50
    if course.only_pp50? &&
        mandatory_institution.eligible_establishment? &&
        work_setting.in?(Questionnaires::WorkSetting::SCHOOL_SETTINGS)

      return FUNDED_ELIGIBILITY_RESULT if mandatory_institution.pp50?(work_setting)

      INELIGIBLE_ESTABLISHMENT_NOT_A_PP50
    end
  end

  # 9
  def eligible_itt_provider
    another_setting_policy if work_setting.in?(Questionnaires::WorkSetting::ANOTHER_SETTING_SETTINGS)
  end

  def get_description_for_funding_status
    key = FUNDING_STATUS_CODE_DESCRIPTIONS.fetch(funding_eligiblity_status_code)
    course_name = localise_sentence_embedded_course_name(course)

    I18n.t(key, course_name:).html_safe if key
  end

  def possible_funding_for_non_pp50_and_fe?
    course.only_pp50? && institution.is_a?(School)
  end

private

  def another_setting_policy
    if lead_mentor_for_accredited_itt_provider?
      if course.npqltd?
        return FUNDED_ELIGIBILITY_RESULT if approved_itt_provider

        return INELIGIBLE_ESTABLISHMENT_TYPE
      end

      return NOT_LEAD_MENTOR_COURSE
    end

    eligible_employment_types = [
      Application.employment_types[:local_authority_virtual_school],
      Application.employment_types[:hospital_school],
      Application.employment_types[:young_offender_institution],
      Application.employment_types[:local_authority_supply_teacher],
    ]

    eligible_course_identifiers = %w[
      npq-senco
      npq-headship
    ]

    if employment_type.in?(eligible_employment_types) && course.identifier.in?(eligible_course_identifiers)
      SUBJECT_TO_REVIEW
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

  def mandatory_institution
    raise MissingMandatoryInstitution if institution.nil?

    institution
  end
end
