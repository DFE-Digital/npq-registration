module Migration::Migrators
  class Application < Base
    ATTRIBUTES_TO_COMPARE = %w[
      headteacher_status
      eligible_for_funding
      funding_choice
      teacher_catchment
      works_in_school
      employer_name
      employment_role
      works_in_nursery
      works_in_childcare
      kind_of_nursery
      targeted_delivery_funding_eligibility
      funding_eligiblity_status_code
      employment_type
      lead_mentor
      primary_establishment
      tsf_primary_eligibility
      tsf_primary_plus_eligibility
      lead_provider_approval_status
    ].freeze

    class << self
      def record_count
        ecf_npq_applications.count
      end

      def model
        :application
      end

      def ecf_npq_applications
        Migration::Ecf::NpqApplication.joins(:participant_identity)
      end
    end

    def call
      run_once { report_applications_not_in_ecf_as_failures }

      migrate(self.class.ecf_npq_applications) do |ecf_npq_application|
        application = applications_by_ecf_id[ecf_npq_application.id]
        raise ActiveRecord::RecordNotFound, "Application not found" unless application

        compare_attributes_values!(ecf_npq_application, application)
      end
    end

  private

    def applications_by_ecf_id
      @applications_by_ecf_id ||= ::Application
        .select(ATTRIBUTES_TO_COMPARE + %i[ecf_id])
        .where(ecf_id: self.class.ecf_npq_applications.pluck(:id))
        .index_by(&:ecf_id)
    end

    def report_applications_not_in_ecf_as_failures
      applications_not_in_ecf = ::Application.where.not(ecf_id: self.class.ecf_npq_applications.pluck(:id)).select(:id)
      applications_not_in_ecf.each { |a| failure_manager.record_failure(a, "NPQApplication not found in ECF") }
    end

    def compare_attributes_values!(ecf_npq_application, application)
      return unless ATTRIBUTES_TO_COMPARE.any? { |attribute| ecf_npq_application[attribute] != application[attribute] }

      application.errors.add(:base, "There are some discrepancies in one or more attributes values")
      raise ActiveRecord::RecordInvalid, application
    end
  end
end
