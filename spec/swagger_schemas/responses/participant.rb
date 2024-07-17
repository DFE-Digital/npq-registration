PARTICIPANT_RESPONSE = {
  v1: {
    description: "A single NPQ participant",
    type: :object,
    required: %i[data],
    properties: {
      data: {
        "$ref": "#/components/schemas/Participant",
      },
    },
  },
}.tap { |h|
  h[:v2] = h[:v1].deep_dup
  h[:v3] = h[:v1].deep_dup
}.freeze
