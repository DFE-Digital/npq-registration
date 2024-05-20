APPLICATION_CHANGE_FUNDED_PLACE_REQUEST = {
  description: "A NPQ application change funded place request",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      "$ref": "#/components/schemas/ApplicationChangeFundedPlaceDataRequest",
    },
  },
}.freeze
