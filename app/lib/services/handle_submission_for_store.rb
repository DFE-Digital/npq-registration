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
          school_urn: school_urn,
          ukprn: ukprn,
          headteacher_status: headteacher_status,
          eligible_for_funding: funding_eligbility,
          funding_choice: funding_choice,
          teacher_catchment: store["teacher_catchment"],
          teacher_catchment_country: store["teacher_catchment_country"].presence,
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

    def school_urn
      if query_store.inside_catchment? && query_store.works_in_school?
        institution(source: store["institution_identifier"]).urn
      end
    end

    def ukprn
      if query_store.inside_catchment? && query_store.works_in_school?
        institution(source: store["institution_identifier"]).ukprn
      end
    end

    def funding_choice
      if course.aso?
        store["aso_funding_choice"]
      else
        store["funding"]
      end
    end

    def headteacher_status
      if course.aso?
        case store["aso_headteacher"]
        when "yes"
          case store["aso_new_headteacher"]
          when "yes"
            "yes_in_first_two_years"
          when "no"
            "yes_over_two_years"
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

    def funding_eligbility
      Services::FundingEligibility.new(
        course: course,
        institution: institution(source: store["institution_identifier"]),
        new_headteacher: new_headteacher?,
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
