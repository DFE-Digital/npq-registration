module Migration::Ecf
  class ParticipantOutcome::Npq < BaseRecord
    self.table_name = "participant_outcomes"

    belongs_to :participant_declaration, class_name: "Migration::Ecf::ParticipantDeclaration"
  end
end
