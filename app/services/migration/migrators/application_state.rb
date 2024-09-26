module Migration::Migrators
  class ApplicationState < Base
    class << self
      def record_count
        ecf_participant_profile_states.count
      end

      def model
        :application_state
      end

      def dependencies
        %i[application lead_provider]
      end

      def ecf_participant_profile_states
        Migration::Ecf::ParticipantProfileState
          .joins(participant_profile: :teacher_profile)
          .includes(:cpd_lead_provider)
          .where(teacher_profile: { user_id: User.ecf_users.pluck(:id) })
      end

      def records_per_worker
        (super / 2.0).ceil
      end
    end

    def call
      migrate(self.class.ecf_participant_profile_states) do |ecf_participant_profile_states|
        states_to_update = []

        ecf_participant_profile_states.each do |ecf_participant_profile_state|
          application_state = ::ApplicationState.new(ecf_id: ecf_participant_profile_state.id)

          ecf_lead_provider_id = ecf_participant_profile_state.cpd_lead_provider&.npq_lead_provider&.id
          application_state.lead_provider_id = self.class.find_lead_provider_id!(ecf_id: ecf_lead_provider_id) if ecf_lead_provider_id

          ecf_application_id = ecf_participant_profile_state.participant_profile_id
          application_state.application_id = self.class.find_application_id!(ecf_id: ecf_application_id)

          application_state.assign_attributes(ecf_participant_profile_state.attributes.slice("state", "reason", "created_at", "updated_at"))

          if application_state.invalid?
            raise ActiveRecord::ActiveRecordError("Validation failed: #{application_state.errors.full_messages.join(', ')}")
          end

          states_to_update << application_state

          increment_processed_count
        rescue ActiveRecord::ActiveRecordError => e
          increment_failure_count(ecf_participant_profile_state, e)
        end

        # Super hacky just to test performance
        attrs = %w[ecf_id lead_provider_id application_id state reason created_at updated_at]
        records = states_to_update.map(&:attributes).map { |attributes| attributes.slice(*attrs) }.map(&:symbolize_keys)
        ::ApplicationState.upsert_all(records, unique_by: :ecf_id)
      end
    end
  end
end
