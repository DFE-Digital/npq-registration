STATEMENT_RESPONSE = {
  v3: {
    description: "A financial statement.",
    type: :object,
    required: %i[data],
    properties: {
      data: {
        "$ref": "#/components/schemas/Statement",
      },
    },
  },
}.freeze
