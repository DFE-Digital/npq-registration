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
        Migration::Ecf::ParticipantDeclaration.includes(:cohort, :declaration_states, cpd_lead_provider: :npq_lead_provider)
      end

      def dependencies
        %i[cohort application lead_provider course user]
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
          cohort: find_cohort!(start_year: ecf_declaration.cohort.start_year),
          lead_provider: find_lead_provider!(ecf_id: ecf_declaration.cpd_lead_provider.npq_lead_provider.id),
          application: find_application!(course_identifier: ecf_declaration.course_identifier, ecf_user_id: ecf_declaration.user_id),
        )
      end
    end

  private

    def find_application!(course_identifier:, ecf_user_id:)
      applications_by_course_identifier_and_ecf_user_id.dig(course_identifier, ecf_user_id) || raise(ActiveRecord::RecordNotFound, "Couldn't find Application")
    end

    def applications_by_course_identifier_and_ecf_user_id
      @applications_by_course_identifier_and_ecf_user_id ||= begin
        applications = ::Application
          .includes(:user, :course)

        applications.each_with_object({}) do |application, hash|
          course_identifier = application.course.identifier
          ecf_user_id = application.user.ecf_id

          hash[course_identifier] ||= {}
          hash[course_identifier][ecf_user_id] = application
        end
      end
    end
  end
end
