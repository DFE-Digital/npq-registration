APPLICATION_ACCEPT_DATA_REQUEST = {
  description: "A NPQ application acceptance request data",
  type: :object,
  required: %i[type attributes],
  properties: {
    type: {
      description: "The data typed",
      type: :string,
      example: "npq-application-accept",
    },
    attributes: {
      "$ref": "#/components/schemas/ApplicationAcceptAttributesRequest",
    },
  },
}.freeze
