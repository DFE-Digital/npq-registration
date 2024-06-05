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
  h[:v2] = h[:v1]
  h[:v3] = h[:v1]
}.freeze
