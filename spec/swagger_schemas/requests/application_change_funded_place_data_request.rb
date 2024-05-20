APPLICATION_CHANGE_FUNDED_PLACE_DATA_REQUEST = {
  description: "A NPQ application change funded place request data",
  type: :object,
  required: %i[type attributes],
  properties: {
    type: {
      description: "The data typed",
      type: :string,
      example: "npq-application-change-funded-place",
    },
    attributes: {
      "$ref": "#/components/schemas/ApplicationChangeFundedPlaceAttributesRequest",
    },
  },
}.freeze
