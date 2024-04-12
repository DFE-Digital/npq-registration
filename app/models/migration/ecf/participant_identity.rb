module Migration::Ecf
  class ParticipantIdentity < BaseRecord
    belongs_to :user
    has_many :participant_profiles
    has_many :npq_applications
  end
end
