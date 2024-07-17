PARTICIPANTS_RESPONSE = {
  v1: {
    description: "A list of NPQ participants.",
    type: :object,
    required: %i[data],
    properties: {
      data: {
        type: :array,
        items: { "$ref": "#/components/schemas/Participant" },
      },
    },
  },
}.tap { |h|
  h[:v2] = h[:v1].deep_dup
  h[:v3] = h[:v2].deep_dup
}.freeze
