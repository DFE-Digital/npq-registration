class Services::QueryStore
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

  def inside_catchment?
    store["teacher_catchment"] == "england"
  end

  def teacher_catchment_humanized
    if store["teacher_catchment"] == "another"
      store["teacher_catchment_country"]
    else
      I18n.t(store["teacher_catchment"], scope: %i[helpers label registration_wizard teacher_catchment_options])
    end
  end

  def lead_mentor_for_accredited_itt_provider?
    store["employment_type"] == "lead_mentor_for_accredited_itt_provider"
  end

  def works_in_school?
    store["works_in_school"] == "yes"
  end

  def works_in_childcare?
    store["works_in_childcare"] == "yes"
  end

  def works_in_other?
    store["work_setting"] == "other"
  end

  def has_ofsted_urn?
    store["has_ofsted_urn"] == "yes"
  end

  def kind_of_nursery_public?
    Forms::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.include?(store["kind_of_nursery"])
  end

  def kind_of_nursery_private?
    Forms::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.include?(store["kind_of_nursery"])
  end

  def course
    @course ||= Course.find_by(identifier: store["course_identifier"])
  end

  def lead_provider
    @lead_provider ||= LeadProvider.find_by(id: store["lead_provider_id"])
  end

  def new_headteacher?
    store["aso_headteacher"] == "yes" && store["aso_new_headteacher"] == "yes"
  end

  def date_of_birth
    store["date_of_birth"]
  end

  def formatted_date_of_birth
    date_of_birth&.to_s(:govuk)
  end
end
