module Migration::Ecf
  class ParticipantOutcomeAPIRequest < BaseRecord
    belongs_to :participant_outcome, class_name: "ParticipantOutcome::Npq"
  end
end
