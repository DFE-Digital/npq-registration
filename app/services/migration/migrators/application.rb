module Migration::Migrators
  class Application < Base
    ATTRIBUTES = %w[
      headteacher_status
      eligible_for_funding
      funding_choice
      works_in_school
      employer_name
      employment_role
      targeted_support_funding_eligibility
      teacher_catchment_iso_country_code
      works_in_nursery
      works_in_childcare
      kind_of_nursery
      targeted_delivery_funding_eligibility
      funding_eligiblity_status_code
      employment_type
      lead_mentor
      primary_establishment
      number_of_pupils
      tsf_primary_eligibility
      tsf_primary_plus_eligibility
      lead_provider_approval_status
      teacher_catchment
      teacher_catchment_country
      notes
      funded_place
    ].freeze

    class << self
      def record_count
        ecf_npq_applications.count
      end

      def model
        :application
      end

      def dependencies
        %i[private_childcare_provider itt_provider cohort lead_provider schedule course user school]
      end

      def ecf_npq_applications
        Migration::Ecf::NpqApplication
          .joins(:participant_identity)
          .includes(:user, profile: :schedule)
      end
    end

    def call
      run_once { report_applications_not_in_ecf_as_failures }

      migrate(self.class.ecf_npq_applications) do |ecf_npq_application|
        application = ::Application.find_by!(ecf_id: ecf_npq_application.id)

        ensure_relationships_are_consistent!(ecf_npq_application, application)

        ecf_schedule = ecf_npq_application.profile&.schedule
        application.schedule_id = find_schedule_id!(ecf_id: ecf_schedule.id) if ecf_schedule

        application.cohort_id = find_cohort_id!(ecf_id: ecf_npq_application.cohort_id)
        application.itt_provider_id = find_itt_provider_id!(itt_provider: ecf_npq_application.itt_provider) if ecf_npq_application.itt_provider
        application.private_childcare_provider_id = find_private_childcare_provider_id!(provider_urn: ecf_npq_application.private_childcare_provider_urn) if ecf_npq_application.private_childcare_provider_urn

        if ecf_npq_application.school_urn.present?
          application.school_id = find_school_id!(urn: ecf_npq_application.school_urn)
        end
        application.lead_provider_id = find_lead_provider_id!(ecf_id: ecf_npq_application.npq_lead_provider_id)
        application.course_id = find_course_id!(ecf_id: ecf_npq_application.npq_course_id)

        application.training_status = ecf_npq_application.profile&.training_status if ecf_npq_application.profile
        application.ukprn = ecf_npq_application.school_ukprn

        application.update!(ecf_npq_application.attributes.slice(*ATTRIBUTES))
      end
    end

  private

    def ensure_relationships_are_consistent!(ecf_npq_application, application)
      if application.user_id != find_user_id!(ecf_id: ecf_npq_application.user.id)
        raise_error(ecf_npq_application, message: "User in ECF is different")
      end
    end

    def raise_error(application, message:)
      application.errors.add(:base, message)
      raise ActiveRecord::RecordInvalid, application
    end

    def report_applications_not_in_ecf_as_failures
      applications_not_in_ecf = ::Application.where.not(ecf_id: self.class.ecf_npq_applications.pluck(:id)).select(:id)
      applications_not_in_ecf.each { |a| failure_manager.record_failure(a, "NPQApplication not found in ECF") }
    end
  end
end
