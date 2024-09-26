module Migration::Migrators
  class ParticipantOutcome < Base
    class << self
      def record_count
        ecf_outcomes.count
      end

      def model
        :participant_outcome
      end

      def ecf_outcomes
        Migration::Ecf::ParticipantOutcome::Npq
      end

      def dependencies
        %i[declaration]
      end
    end

    def call
      migrate(self.class.ecf_outcomes) do |ecf_outcomes|
        outcomes_to_update = []

        ecf_outcomes.each do |ecf_outcome|
          outcome = ::ParticipantOutcome.new(ecf_id: ecf_outcome.id)
          declaration_id = self.class.find_declaration_id!(ecf_id: ecf_outcome.participant_declaration_id)

          outcome.assign_attributes(ecf_outcome.attributes.except("id", "participant_declaration_id").merge({ declaration_id: }))

          # Ignore uniqueness validation on ecf_id as we're doing an upsert
          if outcome.invalid? && outcome.errors.map(&:attribute) != %i[ecf_id]
            raise ActiveRecord::ActiveRecordError("Validation failed: #{outcome.errors.full_messages.join(', ')}")
          end

          outcomes_to_update << outcome

          increment_processed_count
        rescue ActiveRecord::ActiveRecordError => e
          increment_failure_count(ecf_outcome, e)
        end

        # Super hacky just to test performance
        attrs = %w[ecf_id declaration_id created_at updated_at state sent_to_qualified_teachers_api_at qualified_teachers_api_request_successful completion_date completion_date]
        records = outcomes_to_update.map(&:attributes).map { |attributes| attributes.slice(*attrs) }.map(&:symbolize_keys)
        ::ParticipantOutcome.upsert_all(records, unique_by: :ecf_id)
      end
    end
  end
end
