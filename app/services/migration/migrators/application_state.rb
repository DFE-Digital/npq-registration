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
    end

    def call
      migrate(self.class.ecf_participant_profile_states) do |ecf_participant_profile_state|
        application_state = ::ApplicationState.find_or_initialize_by(ecf_id: ecf_participant_profile_state.id)

        ecf_lead_provider_id = ecf_participant_profile_state.cpd_lead_provider&.npq_lead_provider&.id
        application_state.lead_provider = find_lead_provider!(ecf_id: ecf_lead_provider_id) if ecf_lead_provider_id

        ecf_application_id = ecf_participant_profile_state.participant_profile_id
        application_state.application = find_application!(ecf_id: ecf_application_id)

        application_state.update!(ecf_participant_profile_state.attributes.slice(%w[state reason created_at updated_at]))
      end
    end
  end
end
