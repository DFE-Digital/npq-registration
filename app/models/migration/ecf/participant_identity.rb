module Migration::Ecf
  class ParticipantIdentity < Migration::Ecf::BaseRecord
    belongs_to :user
    has_many :npq_applications
  end
end
