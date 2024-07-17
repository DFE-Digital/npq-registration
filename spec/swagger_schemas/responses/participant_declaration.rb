PARTICIPANT_DECLARATION_RESPONSE = {
  v1: {
    description: "A single participant declaration.",
    type: :object,
    required: %i[data],
    properties: {
      data: {
        "$ref": "#/components/schemas/ParticipantDeclaration",
      },
    },
  },
}.tap { |h|
  h[:v2] = h[:v1]
  h[:v3] = h[:v1]
}.freeze
