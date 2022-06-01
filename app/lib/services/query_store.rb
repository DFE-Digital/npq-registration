class Services::QueryStore
  attr_reader :store

  def initialize(store:)
    @store = store
  end

  def inside_catchment?
    store["teacher_catchment"] == "england"
  end

  def where_teach_humanized
    if store["teacher_catchment"] == "another"
      store["teacher_catchment_country"]
    else
      I18n.t(store["teacher_catchment"], scope: %i[activemodel attributes forms/teacher_catchment teacher_catchment])
    end
  end

  def works_in_school?
    store["works_in_school"] == "yes"
  end

  def works_in_childcare?
    store["works_in_childcare"] == "yes"
  end

  def works_in_nursery?
    store["works_in_nursery"] == "yes"
  end

  def has_ofsted_urn?
    store["has_ofsted_urn"] == "yes"
  end

  def works_in_public_childcare_provider?
    works_in_nursery? &&
      Forms::KindOfNursery::KIND_OF_NURSERY_PUBLIC_OPTIONS.include?(store["kind_of_nursery"])
  end

  def works_in_private_childcare_provider?
    works_in_nursery? &&
      Forms::KindOfNursery::KIND_OF_NURSERY_PRIVATE_OPTIONS.include?(store["kind_of_nursery"])
  end

  def course
    @course ||= Course.find(store["course_id"])
  end

  def lead_provider
    @lead_provider ||= LeadProvider.find_by(id: store["lead_provider_id"])
  end

  def new_headteacher?
    store["aso_headteacher"] == "yes" && store["aso_new_headteacher"] == "yes"
  end
end
