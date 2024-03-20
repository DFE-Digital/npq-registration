NOT_FOUND_RESPONSE = {
  description: "The requested resource was not found.",
  type: :object,
  properties: {
    error: {
      type: :string,
      description: "Resource not found",
    },
  },
  example: {
    error: "Resource not found",
  },
}.freeze
