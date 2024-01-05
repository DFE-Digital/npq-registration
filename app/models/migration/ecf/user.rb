module Migration::Ecf
  class User < Migration::Ecf::BaseRecord
    has_many :participant_identities
    has_one :teacher_profile, dependent: :destroy

    delegate :trn, to: :teacher_profile, allow_nil: true
    alias_method :ecf_id, :id

    def participant_identity
      participant_identities.first
    end

    def migration_npq_applications
      @migration_npq_applications ||= NpqApplication.joins(:participant_identity)
      .includes(:school)
      .where(participant_identity: { user_id: id })
      .to_a
    end
    alias_method :applications, :migration_npq_applications
  end
end
