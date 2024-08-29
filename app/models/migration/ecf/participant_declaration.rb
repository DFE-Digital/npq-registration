module Migration::Ecf
  class ParticipantDeclaration < BaseRecord
    self.inheritance_column = nil

    belongs_to :cpd_lead_provider
    belongs_to :user
    belongs_to :cohort
    belongs_to :superseded_by, class_name: "Migration::Ecf::ParticipantDeclaration", optional: true

    has_many :declaration_states
    has_many :supersedes, class_name: "Migration::Ecf::ParticipantDeclaration", foreign_key: :superseded_by_id, inverse_of: :superseded_by

    default_scope { where(type: "ParticipantDeclaration::NPQ") }
  end
end
