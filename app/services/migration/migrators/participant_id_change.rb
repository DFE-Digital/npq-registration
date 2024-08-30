module Migration::Migrators
  class ParticipantIdChange < Base
    class << self
      def record_count
        ecf_participant_id_changes.count
      end

      def model
        :participant_id_change
      end

      def dependencies
        %i[user]
      end

      def ecf_participant_id_changes
        Migration::Ecf::ParticipantIdChange
          .joins(:user)
          .where(user: { id: User.ecf_users.pluck(:id) })
      end
    end

    def call
      migrate(self.class.ecf_participant_id_changes) do |ecf_participant_id_change|
        ecf_ids = ecf_participant_id_change.attributes.slice("user_id", "from_participant_id", "to_participant_id").values
        user_id_by_ecf_id = ::User.where(ecf_id: ecf_ids).select(:id, :ecf_id).index_by(&:ecf_id).transform_values(&:id)

        ::ParticipantIdChange.find_or_create_by!(
          user_id: user_id_by_ecf_id[ecf_participant_id_change.user_id],
          from_participant_id: user_id_by_ecf_id[ecf_participant_id_change.from_participant_id],
          to_participant_id: user_id_by_ecf_id[ecf_participant_id_change.to_participant_id],
        ).tap do |participant_id_change|
          participant_id_change.update!(created_at: ecf_participant_id_change.created_at)
        end
      end
    end
  end
end
