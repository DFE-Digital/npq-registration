class HandleSubmissionForStore
  include Helpers::Institution

  attr_reader :store

  def initialize(store:)
    @store = store
  end

  def call
    ActiveRecord::Base.transaction do
      user.applications.create!(
        course_id: course.id,
        lead_provider_id: store["lead_provider_id"],
        private_childcare_provider_urn:,
        school_urn:,
        ukprn:,
        headteacher_status:,
        eligible_for_funding: eligible_for_funding?,
        funding_eligiblity_status_code:,
        funding_choice:,
        teacher_catchment: store["teacher_catchment"],
        teacher_catchment_country: store["teacher_catchment_country"].presence,
        works_in_school: store["works_in_school"] == "yes",
        employer_name:,
        employment_role:,
        employment_type:,
        targeted_delivery_funding_eligibility:,
        primary_establishment:,
        number_of_pupils:,
        tsf_primary_eligibility:,
        tsf_primary_plus_eligibility:,
        works_in_childcare: store["works_in_childcare"] == "yes",
        kind_of_nursery: store["kind_of_nursery"],
        work_setting: store["work_setting"],
        lead_mentor: lead_mentor?,
        itt_provider:,
        raw_application_data: raw_application_data.except("current_user"),
      )

      enqueue_job
    end
  end

private

  def raw_application_data
    # Cutting out confirmation keys since that is not application related data
    # Though I recognise that this means that even though this is meant to be raw
    # it still has a small layer of processing
    store.except("generated_confirmation_code")
  end

  def query_store
    @query_store ||= QueryStore.new(store:)
  end

  delegate :inside_catchment?, to: :query_store

  def store_employer_data?
    return false if eligible_for_funding?

    ineligible_institution_type? && inside_catchment?
  end

  def lead_mentor?
    store["employment_type"] == "lead_mentor_for_accredited_itt_provider"
  end

  def itt_provider
    store["itt_provider"]
  end

  def primary_establishment
    institution_from_store.is_a?(School) && institution_from_store.primary_education_phase?
  end

  def number_of_pupils
    institution_from_store.is_a?(School) && institution_from_store.number_of_pupils
  end

  def employer_name
    store["employer_name"].presence if store_employer_data?
  end

  def employment_role
    store["employment_role"].presence if store_employer_data?
  end

  def employment_type
    store["employment_type"].presence if store_employer_data? || lead_mentor?
  end

  def institution_from_store
    @institution_from_store ||= institution(source: store["institution_identifier"])
  end

  def store_private_childcare_provider_urn?
    inside_catchment? && institution_from_store.is_a?(PrivateChildcareProvider)
  end

  def private_childcare_provider_urn
    institution_from_store.provider_urn if store_private_childcare_provider_urn?
  end

  def store_school_urn?
    inside_catchment? && institution_from_store.is_a?(School)
  end

  def school_urn
    institution_from_store.urn if store_school_urn?
  end

  def store_ukprn?
    return false unless inside_catchment?

    institution_from_store.is_a?(LocalAuthority) || institution_from_store.is_a?(School)
  end

  def ukprn
    institution_from_store.ukprn if store_ukprn?
  end

  def funding_choice
    # It is possible that the applicant had chosen a non-funded path and selected a funding choice
    # before going back a few steps and choosing a funded route. We should clear the funding choice
    # to nil here to reduce confusion
    if eligible_for_funding?
      nil
    elsif course.ehco?
      store["ehco_funding_choice"]
    else
      store["funding"]
    end
  end

  def headteacher_status
    if course.ehco?
      case store["ehco_headteacher"]
      when "yes"
        case store["ehco_new_headteacher"]
        when "yes"
          "yes_in_first_five_years"
        when "no"
          "yes_over_five_years"
        end
      when "no"
        "no"
      end
    else
      store["headteacher_status"]
    end
  end

  def enqueue_job
    ApplicationSubmissionJob.perform_later(user:, email_template:)
  end

  def funding_eligibility_service
    @funding_eligibility_service ||= FundingEligibility.new(
      course:,
      institution: institution_from_store,
      approved_itt_provider:,
      lead_mentor: lead_mentor?,
      inside_catchment: inside_catchment?,
      new_headteacher: new_headteacher?,
      trn: query_store.trn,
      get_an_identity_id: query_store.get_an_identity_id,
    )
  end

  def approved_itt_provider
    ::IttProvider.currently_approved
      .find_by(legal_name: store["itt_provider"]).present?
  end

  def eligible_for_funding?
    funding_eligibility_service.funded?
  end

  def email_template
    EmailTemplateLookup.call(store["email_template"])
  end

  def targeted_delivery_funding_eligibility
    targeted_funding[:targeted_delivery_funding] && !previously_received_targeted_funding_support?
  end

  def tsf_primary_eligibility
    targeted_funding[:tsf_primary_eligibility]
  end

  def tsf_primary_plus_eligibility
    targeted_funding[:tsf_primary_plus_eligibility]
  end

  def targeted_funding
    @targeted_funding ||= targeted_funding
  end

  delegate :ineligible_institution_type?,
           :funding_eligiblity_status_code,
           :previously_received_targeted_funding_support?,
           :targeted_funding,
           to: :funding_eligibility_service

  def new_headteacher?
    %w[yes_in_first_two_years yes_in_first_five_years yes_when_course_starts].include?(headteacher_status)
  end

  def course
    @course ||= query_store.course
  end

  def school
    @school ||= School.find_by(urn: store["school_urn"])
  end

  def user
    @user ||= store["current_user"]
  end
end
