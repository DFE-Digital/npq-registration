module Migration::Migrators
  class Declaration < Base
    class << self
      def record_count
        ecf_declarations.count
      end

      def model
        :declaration
      end

      def ecf_declarations
        Migration::Ecf::ParticipantDeclaration.includes(:declaration_states, cpd_lead_provider: :npq_lead_provider)
      end

      def dependencies
        %i[cohort application lead_provider course user]
      end

      def records_per_worker
        (super / 2.0).ceil
      end
    end

    def call
      migrate(self.class.ecf_declarations) do |ecf_declaration|
        declaration = ::Declaration.find_or_initialize_by(ecf_id: ecf_declaration.id)
        latest_declaration_state = ecf_declaration.declaration_states.detect(&:ineligible?)

        declaration.update!(
          created_at: ecf_declaration.created_at,
          updated_at: ecf_declaration.updated_at,
          declaration_type: ecf_declaration.declaration_type,
          declaration_date: ecf_declaration.declaration_date,
          state: ecf_declaration.state,
          state_reason: latest_declaration_state&.state_reason,
          cohort_id: find_cohort_id!(ecf_id: ecf_declaration.cohort_id),
          lead_provider_id: find_lead_provider_id!(ecf_id: ecf_declaration.cpd_lead_provider.npq_lead_provider.id),
          application_id: find_application_id!(course_identifier: ecf_declaration.course_identifier, ecf_user_id: ecf_declaration.user_id),
          skip_declaration_date_within_schedule_validation: true,
        )
      end
    end

  private

    def find_application_id!(course_identifier:, ecf_user_id:)
      application_ids_by_course_identifier_and_ecf_user_id.dig(course_identifier.downcase, ecf_user_id) || raise(ActiveRecord::RecordNotFound, "Couldn't find Application")
    end

    def application_ids_by_course_identifier_and_ecf_user_id
      @application_ids_by_course_identifier_and_ecf_user_id ||= begin
        applications = ::Application.joins(:user, :course).pluck(:id, :identifier, "users.ecf_id")
        applications.each_with_object({}) do |(id, course_identifier, ecf_user_id), hash|
          hash[course_identifier.downcase] ||= {}
          hash[course_identifier.downcase][ecf_user_id] = id
        end
      end
    end
  end
end
