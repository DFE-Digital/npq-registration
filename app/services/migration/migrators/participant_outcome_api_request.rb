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
      migrate(self.class.ecf_outcome_api_requests) do |ecf_outcome_api_requests|
        api_requests_to_update = []

        ecf_outcome_api_requests.each do |ecf_outcome_api_request|
          outcome_api_request = ::ParticipantOutcomeAPIRequest.new(ecf_id: ecf_outcome_api_request.id)
          participant_outcome_id = ::ParticipantOutcome.select(:id).find_by!(ecf_id: ecf_outcome_api_request.participant_outcome_id).id

          outcome_api_request.assign_attributes(ecf_outcome_api_request.attributes.except("id", "participant_outcome_id").merge({ participant_outcome_id: }))

          if outcome_api_request.invalid? && outcome_api_request.errors.map(&:attribute) != %i[ecf_id]
            raise ActiveRecord::ActiveRecordError("Validation failed: #{outcome_api_request.errors.full_messages.join(', ')}")
          end

          api_requests_to_update << outcome_api_request

          increment_processed_count
        rescue ActiveRecord::ActiveRecordError => e
          increment_failure_count(ecf_outcome_api_request, e)
        end

        # Super hacky just to test performance
        attrs = %w[ecf_id participant_outcome_id status_code status_headers request_path request_body response_body response_headers created_at updated_at]
        records = outcome_api_request.map(&:attributes).map { |attributes| attributes.slice(*attrs) }.map(&:symbolize_keys)
        ::ParticipantOutcomeAPIRequest.upsert_all(records, unique_by: :ecf_id)
      end
    end
  end
end
