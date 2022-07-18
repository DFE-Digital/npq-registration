module Services
  class HandleSubmissionForStore
    include Forms::Helpers::Institution

    attr_reader :store

    def initialize(store:)
      @store = store
    end

    def call
      ActiveRecord::Base.transaction do
        user.update!(
          trn: padded_verified_trn || padded_entered_trn,
          trn_verified: store["trn_verified"],
          trn_auto_verified: !!store["trn_auto_verified"],
          active_alert: store["active_alert"],
          full_name: store["full_name"],
          date_of_birth: store["date_of_birth"],
          national_insurance_number: ni_number_to_store,
        )

        user.applications.create!(
          course_id: course.id,
          lead_provider_id: store["lead_provider_id"],
          private_childcare_provider_urn:,
          school_urn:,
          ukprn:,
          headteacher_status:,
          eligible_for_funding: funding_eligibility,
          funding_eligiblity_status_code:,
          funding_choice:,
          teacher_catchment: store["teacher_catchment"],
          teacher_catchment_country: store["teacher_catchment_country"].presence,
          works_in_school: store["works_in_school"] == "yes",
          employer_name:,
          employment_role:,
          targeted_delivery_funding_eligibility:,
          works_in_nursery: store["works_in_nursery"] == "yes",
          works_in_childcare: store["works_in_childcare"] == "yes",
          kind_of_nursery: store["kind_of_nursery"],
          cohort: course.default_cohort,
          raw_application_data:,
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

    def padded_entered_trn
      store["trn"].rjust(7, "0")
    end

    def padded_verified_trn
      if store["verified_trn"].present?
        store["verified_trn"].rjust(7, "0")
      end
    end

    def query_store
      @query_store ||= Services::QueryStore.new(store:)
    end

    delegate :inside_catchment?, to: :query_store

    def store_employer_data?
      return false if eligible_for_funding?

      ineligible_institution_type? && inside_catchment?
    end

    def employer_name
      store["employer_name"].presence if store_employer_data?
    end

    def employment_role
      store["employment_role"].presence if store_employer_data?
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
      if funding_eligibility
        nil
      elsif course.ehco?
        store["aso_funding_choice"]
      else
        store["funding"]
      end
    end

    def headteacher_status
      if course.ehco?
        case store["aso_headteacher"]
        when "yes"
          case store["aso_new_headteacher"]
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
      ApplicationSubmissionJob.perform_later(user:)
    end

    def funding_eligibility_service
      @funding_eligibility_service ||= Services::FundingEligibility.new(
        course:,
        institution: institution_from_store,
        inside_catchment: inside_catchment?,
        new_headteacher: new_headteacher?,
        trn: store["trn"],
      )
    end

    def eligible_for_funding?
      funding_eligibility_service.funded?
    end

    def funding_eligibility
      eligible_for_funding?
    end

    delegate :ineligible_institution_type?,
             :funding_eligiblity_status_code,
             to: :funding_eligibility_service

    def targeted_delivery_funding_eligibility
      @targeted_delivery_funding_eligibility ||= Services::Eligibility::TargetedDeliveryFunding.new(
        institution: institution_from_store,
        course:,
      ).call
    end

    def new_headteacher?
      %w[yes_in_first_two_years yes_in_first_five_years yes_when_course_starts].include?(headteacher_status)
    end

    def ni_number_to_store
      store["national_insurance_number"] unless store["trn_verified"]
    end

    def course
      @course ||= Course.find(store["course_id"])
    end

    def school
      @school ||= School.find_by(urn: store["school_urn"])
    end

    def user
      @user ||= User.find_by(email: store["confirmed_email"])
    end
  end
end
