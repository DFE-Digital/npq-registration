PARTICIPANT_OUTCOME_RESPONSE = {
  v1: {
    description: "The details of an NPQ Outcome",
    type: :object,
    required: %i[data],
    properties: {
      data: {
        "$ref": "#/components/schemas/ParticipantOutcome",
      },
    },
  },
}.tap { |h|
  h[:v2] = h[:v1].deep_dup
  h[:v3] = h[:v1].deep_dup
}.freeze
