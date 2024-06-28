PARTICIPANT_RESUME_REQUEST = {
  description: "A participant resume request",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      description: "A participant resume request data",
      type: :object,
      required: %i[type attributes],
      properties: {
        type: {
          description: "The data typed",
          type: :string,
          example: "participant-resume",
          required: true,
        },
        attributes: {
          description: "A participant resume request attributes",
          type: :object,
          required: %i[course_identifier],
          properties: {
            course_identifier: {
              description: "The type of course the participant is enrolled in",
              required: true,
              nullable: false,
              type: :string,
              example: Course::IDENTIFIERS.first,
              enum: Course::IDENTIFIERS,
            },
          },
        },
      },
    },
  },
}.freeze
