APPLICATION_CHANGE_FUNDED_PLACE_REQUEST = {
  description: "A NPQ application change funded place request",
  type: :object,
  required: %i[data],
  properties: {
    data: {
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
          description: "A NPQ application change funded place request attributes",
          type: :object,
          required: %i[funded_place],
          properties: {
            funded_place: {
              description: "This field indicates whether the application is funded",
              nullable: false,
              type: :boolean,
              required: true,
              example: true,
            },
          },
        },
      },
    },
  },
}.freeze