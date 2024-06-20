APPLICATIONS_RESPONSE = {
  v1: {
    description: "A list of NPQ applications.",
    type: :object,
    required: %i[data],
    properties: {
      data: {
        type: :array,
        items: { "$ref": "#/components/schemas/Application" },
      },
    },
  },
}.tap { |h|
  h[:v2] = h[:v1].deep_dup
  h[:v3] = h[:v2].deep_dup
}.freeze
