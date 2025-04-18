class RegistrationQueryStore
  attr_reader :store

  def initialize(store:)
    @store = store
  end

  def current_user
    store["current_user"]
  end

  def itt_provider
    store["itt_provider"]
  end

  def approved_itt_provider?
    ::IttProvider.currently_approved.find_by(legal_name: itt_provider).present?
  end

  def get_an_identity_id
    current_user.get_an_identity_id
  end

  def trn_set_via_fallback_verification_question?
    store["trn_set_via_fallback_verification_question"]
  end

  def trn
    current_user.trn
  end

  def funding_amount
    store["funding_amount"]
  end

  def inside_catchment?
    store["teacher_catchment"] == "england"
  end

  def tsf_primary_eligibility?
    store["tsf_primary_eligibility"]
  end

  def tsf_primary_plus_eligibility?
    store["tsf_primary_plus_eligibility"]
  end

  def funding_eligiblity_status_code
    store["funding_eligiblity_status_code"]
  end

  def targeted_delivery_funding_eligibility?
    store["targeted_delivery_funding_eligibility"]
  end

  def teacher_catchment_humanized
    case store["teacher_catchment"]
    when "another"
      "No"
    when "england"
      "Yes"
    end
  end

  def lead_mentor_for_accredited_itt_provider?
    store["employment_type"] == "lead_mentor_for_accredited_itt_provider"
  end

  def employment_type_other?
    store["employment_type"] == "other"
  end

  def employment_type_local_authority_virtual_school?
    store["employment_type"] == "local_authority_virtual_school"
  end

  def local_authority_supply_teacher?
    store["employment_type"] == "local_authority_supply_teacher"
  end

  def employment_type_hospital_school?
    store["employment_type"] == "hospital_school"
  end

  def young_offender_institution?
    store["employment_type"] == "young_offender_institution"
  end

  def teacher_catchment_england?
    store["teacher_catchment"] == "england"
  end

  def valid_employent_type_for_england?
    teacher_catchment_england? && !employment_type_other? && !lead_mentor_for_accredited_itt_provider?
  end

  def works_in_school?
    store["works_in_school"] == "yes"
  end

  def works_in_childcare?
    store["works_in_childcare"] == "yes"
  end

  def works_in_another_setting?
    store["work_setting"] == "another_setting"
  end

  def works_in_other?
    store["work_setting"] == "other"
  end

  def has_ofsted_urn?
    store["has_ofsted_urn"] == "yes"
  end

  def referred_by_return_to_teaching_adviser?
    store["referred_by_return_to_teaching_adviser"] == "yes"
  end

  def kind_of_nursery_public?
    Questionnaires::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.include?(store["kind_of_nursery"])
  end

  def kind_of_nursery_private?
    Questionnaires::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.include?(store["kind_of_nursery"])
  end

  def course
    @course ||= Course.find_by(identifier: store["course_identifier"])
  end

  def lead_provider
    @lead_provider ||= LeadProvider.find_by(id: store["lead_provider_id"])
  end

  def new_headteacher?
    store["ehco_headteacher"] == "yes" && store["ehco_new_headteacher"] == "yes"
  end

  def date_of_birth
    store["date_of_birth"]
  end

  def formatted_date_of_birth
    date_of_birth&.to_fs(:govuk)
  end

  def maths_understanding?
    store["maths_understanding"]
  end

  def senco_in_role
    store["senco_in_role"]
  end

  def senco_in_role_status?
    store["senco_in_role_status"]
  end

  def senco_start_date
    store["senco_start_date"]
  end

  def childminder?
    store["kind_of_nursery"] == "childminder"
  end

  def work_setting
    store["work_setting"]
  end

  def employment_type_matters?
    (works_in_another_setting? && inside_catchment?) || lead_mentor_for_accredited_itt_provider?
  end

  def employment_role_matters?
    return false unless employment_type_matters?

    !(lead_mentor_for_accredited_itt_provider? || employment_type_hospital_school? || young_offender_institution? || employment_type_other?)
  end

  def employer_name_matters?
    return true if referred_by_return_to_teaching_adviser?
    return false unless employment_type_matters?

    !(lead_mentor_for_accredited_itt_provider? || employment_type_other?)
  end
end
