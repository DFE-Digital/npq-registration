module Migration::Ecf::Finance
  class StatementLineItem < Migration::Ecf::BaseRecord
    self.table_name = "statement_line_items"

    belongs_to :statement
    belongs_to :participant_declaration, class_name: "Migration::Ecf::ParticipantDeclaration"
  end
end
