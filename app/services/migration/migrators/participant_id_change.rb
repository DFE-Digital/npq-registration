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
        participant_id_change = ::ParticipantIdChange.find_or_initialize_by(ecf_id: ecf_participant_id_change.id)

        participant_id_change.update!(
          user: find_user!(ecf_id: ecf_participant_id_change.user_id),
          from_participant_id: ecf_participant_id_change.from_participant_id,
          to_participant_id: ecf_participant_id_change.to_participant_id,
          created_at: ecf_participant_id_change.created_at,
          updated_at: ecf_participant_id_change.updated_at,
        )
      end
    end

  private

    def find_user!(ecf_id:)
      users_by_ecf_id[ecf_id] || raise(ActiveRecord::RecordNotFound, "Couldn't find User")
    end

    def users_by_ecf_id
      @users_by_ecf_id ||= begin
        ecf_ids = self.class.ecf_participant_id_changes.pluck(:user_id).flatten.uniq
        ::User.where(ecf_id: ecf_ids).select(:id, :ecf_id).index_by(&:ecf_id)
      end
    end
  end
end
