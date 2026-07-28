APPLICATION_ACCEPT_REQUEST = {
  v3: {
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
  h[:v3][:properties][:data][:properties][:attributes][:properties][:schedule_identifier] = {
    description: "An optional schedule for the participant - best practice is not to specify this, in which case the most appropriate schedule will be automatcally set",
    nullable: true,
    type: :string,
    example: Schedule::IDENTIFIERS.first,
    enum: Schedule::IDENTIFIERS,
  }
}.freeze
