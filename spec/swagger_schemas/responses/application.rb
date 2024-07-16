APPLICATION_RESPONSE = {
  v1: {
    description: "A single NPQ application",
    type: :object,
    required: %i[data],
    properties: {
      data: {
        "$ref": "#/components/schemas/Application",
      },
    },
  },
}.tap { |h|
  h[:v2] = h[:v1].deep_dup
  h[:v3] = h[:v1].deep_dup
}.freeze
