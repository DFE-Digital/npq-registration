APPLICATION_ACCEPT_REQUEST = {
  description: "A NPQ application acceptance request",
  type: :object,
  properties: {
    data: {
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
          description: "A NPQ application acceptance request attributes",
          type: :object,
          properties: {
            funded_place: {
              description: "This field indicates whether the application is funded",
              nullable: false,
              type: :boolean,
              required: false,
              example: true,
            },
          },
        },
      },
    },
  },
}.freeze

APPLICATION_ACCEPT_REQUEST_V3 = {
  description: "A NPQ application acceptance request",
  type: :object,
  properties: {
    data: {
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
          description: "A NPQ application acceptance request attributes",
          type: :object,
          properties: {
            funded_place: {
              description: "This field indicates whether the application is funded",
              nullable: false,
              type: :boolean,
              required: false,
              example: true,
            },
            schedule_identifier: {
              description: "The new schedule of the participant",
              nullable: false,
              type: :string,
              required: false,
              example: "npq-leadership-autumn",
            },
          },
        },
      },
    },
  },
}.freeze
