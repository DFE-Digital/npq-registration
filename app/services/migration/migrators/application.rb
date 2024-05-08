module Migration::Migrators
  class Application < Base
    ATTRIBUTES_TO_COMPARE = %i[
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

    def call
      migrate(ecf_npq_applications, group: true) do |ecf_npq_application|
        application = ::Application.find_by!(ecf_id: ecf_npq_application.id)

        compare_attributes_values!(ecf_npq_application, application)
      end

      migrate(applications_not_in_ecf) do |application_not_in_ecf|
        Migration::Ecf::NpqApplication.joins(:participant_identity).find_by!(id: application_not_in_ecf.ecf_id)
      end
    end

  private

    def applications
      @applications ||= ::Application.joins(:user).all
    end

    def ecf_npq_applications
      @ecf_npq_applications ||= Migration::Ecf::NpqApplication.joins(:participant_identity).all
    end

    def compare_attributes_values!(ecf_npq_application, application)
      return if ecf_npq_application.attributes.slice(*ATTRIBUTES_TO_COMPARE.map(&:to_s)) ==
        application.attributes.slice(*ATTRIBUTES_TO_COMPARE.map(&:to_s))

      application.errors.add(:base, "There are some discrepancies in one or more attributes values")
      raise ActiveRecord::RecordInvalid, application
    end

    def applications_not_in_ecf
      ::Application.where(ecf_id: applications.map(&:ecf_id).difference(ecf_npq_applications.map(&:id)).compact)
    end
  end
end
