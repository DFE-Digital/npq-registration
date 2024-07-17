PARTICIPANT_WITHDRAW_REQUEST = {
  description: "A participant withdraw request",
  type: :object,
  required: %i[data],
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
          required: true,
        },
        attributes: {
          description: "A participant withdraw request attributes",
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
              description: "The reason for the withdrawal",
              required: true,
              nullable: false,
              type: :string,
              example: Participants::Withdraw::WITHDRAWAL_REASONS.first,
              enum: Participants::Withdraw::WITHDRAWAL_REASONS,
            },
          },
        },
      },
    },
  },
}.freeze
