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
      migrate(self.class.ecf_outcomes) do |ecf_outcome|
        outcome = ::ParticipantOutcome.find_or_initialize_by(ecf_id: ecf_outcome.id)
        declaration_id = find_declaration_id!(ecf_id: ecf_outcome.participant_declaration_id)

        outcome.update!(ecf_outcome.attributes.except("id", "participant_declaration_id").merge({ declaration_id: }))
      end
    end
  end
end
