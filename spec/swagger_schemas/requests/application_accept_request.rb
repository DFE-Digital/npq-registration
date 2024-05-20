APPLICATION_ACCEPT_REQUEST = {
  description: "A NPQ application acceptance request",
  type: :object,
  properties: {
    data: {
      "$ref": "#/components/schemas/ApplicationAcceptDataRequest",
    },
  },
}.freeze
