APPLICATION_ACCEPT_REQUEST = {
  v1: {
    description: "A NPQ application acceptance request",
    type: :object,
    required: %i[data],
    properties: {
      data: {
        description: "A NPQ application acceptance request data",
        type: :object,
        required: %i[type attributes],
        properties: {
          type: {
            description: "The data typed",
            type: :string,
            required: true,
            example: "npq-application-accept",
          },
          attributes: {
            description: "A NPQ application acceptance request attributes",
            type: :object,
            required: false,
            properties: {
              funded_place: {
                description: "Whether the participant has a funded place",
                nullable: false,
                type: :boolean,
                example: true,
              },
            },
          },
        },
      },
    },
  },
}.tap { |h|
  h[:v2] = h[:v1].deep_dup
  h[:v3] = h[:v2].deep_dup
  h[:v3][:properties][:data][:properties][:attributes][:properties][:schedule_identifier] = {
    description: "The new schedule of the participant",
    nullable: false,
    type: :string,
    example: Schedule::IDENTIFIERS.first,
    enum: Schedule::IDENTIFIERS,
  }
}.freeze
