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
          private_childcare_provider_urn: private_childcare_provider_urn,
          school_urn: school_urn,
          ukprn: ukprn,
          headteacher_status: headteacher_status,
          eligible_for_funding: funding_eligibility,
          funding_eligiblity_status_code: funding_eligiblity_status_code,
          funding_choice: funding_choice,
          teacher_catchment: store["teacher_catchment"],
          teacher_catchment_country: store["teacher_catchment_country"].presence,
          works_in_school: store["works_in_school"] == "yes",
          employer_name: store["employer_name"].presence,
          employment_role: store["employment_role"].presence,
          targeted_delivery_funding_eligibility: targeted_delivery_funding_eligibility,
          works_in_nursery: store["works_in_nursery"] == "yes",
          works_in_childcare: store["works_in_childcare"] == "yes",
          kind_of_nursery: store["kind_of_nursery"],
          cohort: Application::TARGET_COHORT,
        )

        enqueue_job
      end
    end

  private

    def padded_entered_trn
      store["trn"].rjust(7, "0")
    end

    def padded_verified_trn
      if store["verified_trn"].present?
        store["verified_trn"].rjust(7, "0")
      end
    end

    def query_store
      @query_store ||= Services::QueryStore.new(store: store)
    end

    def private_childcare_provider_urn
      if query_store.inside_catchment? && query_store.works_in_private_childcare_provider?
        institution(source: store["institution_identifier"]).provider_urn
      end
    end

    def store_school_urn_data?
      return false unless query_store.inside_catchment?

      query_store.works_in_school? || query_store.works_in_public_childcare_provider?
    end

    def school_urn
      if store_school_urn_data?
        institution(source: store["institution_identifier"]).urn
      end
    end

    def ukprn
      if store_school_urn_data?
        institution(source: store["institution_identifier"]).ukprn
      end
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
      ApplicationSubmissionJob.perform_later(user: user)
    end

    def funding_eligibility_service
      @funding_eligibility_service ||= Services::FundingEligibility.new(
        course: course,
        institution: institution(source: store["institution_identifier"]),
        inside_catchment: query_store.inside_catchment?,
        new_headteacher: new_headteacher?,
      )
    end

    def funding_eligibility
      funding_eligibility_service.funded?
    end

    def funding_eligiblity_status_code
      funding_eligibility_service.funding_eligiblity_status_code
    end

    def targeted_delivery_funding_eligibility
      @targeted_delivery_funding_eligibility ||= Services::Eligibility::TargetedDeliveryFunding.new(
        institution: institution(source: store["institution_identifier"]),
      ).call
    end

    def new_headteacher?
      %w[yes_in_first_two_years yes_when_course_starts].include?(headteacher_status)
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
