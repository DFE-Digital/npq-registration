PARTICIPANT_WITHDRAW_REQUEST = {
  description: "A participant withdraw request",
  type: :object,
  properties: {
    data: {
      description: "A participant withdraw request data",
      type: :object,
      required: %i[type attributes],
      properties: {
        type: {
          description: "The data typed",
          type: :string,
          example: "participant-withdraw",
        },
        attributes: {
          description: "A participant withdraw request attributes",
          type: :object,
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
              description: "The reason for the withdrawl",
              required: true,
              nullable: false,
              type: :string,
              example: Participants::Withdraw::WITHDRAWL_REASONS.first,
              enum: Participants::Withdraw::WITHDRAWL_REASONS,
            },
          },
        },
      },
    },
  },
}.freeze
