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
          required: true,
          example: "npq-application-change-funded-place",
        },
        attributes: {
          description: "A NPQ application change funded place request attributes",
          type: :object,
          required: %i[funded_place],
          properties: {
            funded_place: {
              description: "Whether the participant has a funded place",
              nullable: false,
              required: true,
              type: :boolean,
              example: true,
            },
          },
        },
      },
    },
  },
}.freeze
