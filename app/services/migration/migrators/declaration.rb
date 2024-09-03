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
          cohort: cohorts_by_start_year[ecf_declaration.cohort.start_year],
          lead_provider: lead_providers_by_ecf_id[ecf_declaration.cpd_lead_provider.npq_lead_provider.id],
          application: application(ecf_declaration.course_identifier, ecf_declaration.user_id),
        )
      end
    end

  private

    def cohorts_by_start_year
      @cohorts_by_start_year ||= ::Cohort.all.index_by(&:start_year)
    end

    def lead_providers_by_ecf_id
      @lead_providers_by_ecf_id ||= ::LeadProvider.all.index_by(&:ecf_id)
    end

    def application(course_identifier, ecf_user_id)
      ::Application.includes(:user, :course).find_by(course: { identifier: course_identifier }, user: { ecf_id: ecf_user_id })
    end
  end
end
