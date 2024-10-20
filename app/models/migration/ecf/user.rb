module Migration::Ecf
  class User < BaseRecord
    has_many :participant_identities, dependent: :destroy
    has_one :teacher_profile
    has_many :npq_profiles, through: :teacher_profile, dependent: :destroy
    has_many :participant_id_changes

    def npq_applications
      Migration::Ecf::NpqApplication.joins(:participant_identity).where(participant_identity: { user_id: id })
    end
  end
end
