module Migration::Ecf
  class ParticipantProfileState < BaseRecord
    belongs_to :participant_profile
    belongs_to :cpd_lead_provider, optional: true
  end
end
