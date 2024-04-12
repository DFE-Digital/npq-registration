module Migration::Ecf
  class TeacherProfile < BaseRecord
    belongs_to :user
    has_many :npq_profiles, class_name: "ParticipantProfile"
    has_many :participant_profiles
  end
end
