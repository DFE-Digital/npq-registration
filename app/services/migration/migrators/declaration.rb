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
      migrate(self.class.ecf_declarations) do |ecf_declarations|
        declarations_to_update = []

        ecf_declarations.each do |ecf_declaration|
          declaration = ::Declaration.new(ecf_id: ecf_declaration.id)
          latest_declaration_state = ecf_declaration.declaration_states.detect(&:ineligible?)

          declaration.assign_attributes(
            created_at: ecf_declaration.created_at,
            updated_at: ecf_declaration.updated_at,
            declaration_type: ecf_declaration.declaration_type,
            declaration_date: ecf_declaration.declaration_date,
            state: ecf_declaration.state,
            state_reason: latest_declaration_state&.state_reason,
            cohort_id: self.class.find_cohort_id!(ecf_id: ecf_declaration.cohort_id),
            lead_provider_id: self.class.find_lead_provider_id!(ecf_id: ecf_declaration.cpd_lead_provider.npq_lead_provider.id),
            application_id: find_application_id!(course_identifier: ecf_declaration.course_identifier, ecf_user_id: ecf_declaration.user_id),
          )

          if declaration.invalid?
            raise ActiveRecord::ActiveRecordError("Validation failed: #{declaration.errors.full_messages.join(', ')}")
          end

          declarations_to_update << declaration

          increment_processed_count
        rescue ActiveRecord::ActiveRecordError => e
          increment_failure_count(ecf_declaration, e)
        end

        # Super hacky just to test performance
        attrs = %w[ecf_id created_at updated_at declaration_type declaration_date state state_reason cohort_id lead_provider_id application_id]
        records = declarations_to_update.map(&:attributes).map { |attributes| attributes.slice(*attrs) }.map(&:symbolize_keys)
        ::Declaration.upsert_all(records, unique_by: :ecf_id)
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
