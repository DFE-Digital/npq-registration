module Migration::Migrators
  class ParticipantOutcomeAPIRequest < Base
    class << self
      def record_count
        ecf_outcome_api_requests.count
      end

      def model
        :participant_outcome_api_request
      end

      def ecf_outcome_api_requests
        Migration::Ecf::ParticipantOutcomeAPIRequest
      end

      def dependencies
        %i[participant_outcome]
      end
    end

    def call
      migrate(self.class.ecf_outcome_api_requests) do |ecf_outcome_api_request|
        outcome_api_request = ::ParticipantOutcomeAPIRequest.find_or_initialize_by(ecf_id: ecf_outcome_api_request.id)
        participant_outcome_id = ::ParticipantOutcome.select(:id).find_by!(ecf_id: ecf_outcome_api_request.participant_outcome_id).id

        outcome_api_request.update!(ecf_outcome_api_request.attributes.except("id", "participant_outcome_id").merge({ participant_outcome_id: }))
      end
    end
  end
end
