UNAUTHORISED_RESPONSE = {
  description: "Authorization information is missing or invalid.",
  type: :object,
  properties: {
    error: {
      type: :string,
      example: "HTTP Token: Access denied",
    },
  },
}.freeze
