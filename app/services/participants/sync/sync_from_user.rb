module Participants
  module Sync
    class SyncFromUser
      attr_reader :user, :participant

      def initialize(user)
        @user = user
        @participant = Participant.find_or_initialize_by(id: user.id)
      end

      def sync!
        participant.tap do |p|
          p.created_at = user.created_at
          p.date_of_birth = user.date_of_birth
          p.email = user.email
          p.full_name = user.full_name
          p.get_an_identity_id_synced_to_ecf = user.get_an_identity_id_synced_to_ecf
          p.provider = user.provider
          p.raw_tra_provider_data = user.raw_tra_provider_data
          p.trn = user.trn
          p.trn_lookup_state = user.trn_lookup_status
          p.trn_verified = user.trn_verified
          p.updated_at = user.updated_at

          Rails.logger.debug("Syncing participant #{user.id}")
          p.save!
        end
      end
    end
  end
end
