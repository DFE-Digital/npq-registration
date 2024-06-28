PARTICIPANT_DEFER_REQUEST = {
  description: "A participant defer request",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      description: "A participant defer request data",
      type: :object,
      required: %i[type attributes],
      properties: {
        type: {
          description: "The data typed",
          type: :string,
          required: true,
          example: "participant-defer",
        },
        attributes: {
          description: "A participant defer request attributes",
          type: :object,
          required: %i[course_identifier reason],
          properties: {
            course_identifier: {
              description: "The type of course the participant is enrolled in",
              required: true,
              nullable: false,
              type: :string,
              example: Course::IDENTIFIERS.first,
              enum: Course::IDENTIFIERS,
            },
            reason: {
              description: "The reason for the deferral",
              required: true,
              nullable: false,
              type: :string,
              example: Participants::Defer::DEFERRAL_REASONS.first,
              enum: Participants::Defer::DEFERRAL_REASONS,
            },
          },
        },
      },
    },
  },
}.freeze
