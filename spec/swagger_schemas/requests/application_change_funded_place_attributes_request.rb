APPLICATION_CHANGE_FUNDED_PLACE_ATTRIBUTES_REQUEST = {
  description: "A NPQ application change funded place request attributes",
  type: :object,
  required: %i[funded_place],
  properties: {
    funded_place: {
      description: "This field indicates whether the application is funded",
      nullable: false,
      type: :boolean,
      example: true,
    },
  },
}.freeze
