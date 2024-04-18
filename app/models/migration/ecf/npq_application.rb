module Migration::Ecf
  class NpqApplication < BaseRecord
    belongs_to :participant_identity
    belongs_to :npq_lead_provider
    belongs_to :npq_course
    belongs_to :cohort, optional: true
    has_one :profile, class_name: "ParticipantProfile", foreign_key: :id
    has_one :user, through: :participant_identity
    has_one :school, class_name: "School", foreign_key: :urn, primary_key: :school_urn
  end
end
