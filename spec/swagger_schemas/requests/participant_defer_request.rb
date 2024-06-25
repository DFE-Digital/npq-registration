PARTICIPANT_DEFER_REQUEST = {
  description: "A participant defer request",
  type: :object,
  properties: {
    data: {
      description: "A participant defer request data",
      type: :object,
      required: %i[type attributes],
      properties: {
        type: {
          description: "The data typed",
          type: :string,
        },
        attributes: {
          description: "A participant defer request attributes",
          type: :object,
          properties: {
            course_identifier: {
              description: "The type of course the participant is enrolled in",
              required: true,
              nullable: false,
              type: :string,
              enum: Course::IDENTIFIERS,
            },
            reason: {
              description: "The reason for the deferral",
              required: true,
              nullable: false,
              type: :string,
              enum: Participants::Defer::DEFERRAL_REASONS,
            },
          },
        },
      },
    },
  },
}.freeze
