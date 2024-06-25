PARTICIPANT_RESUME_REQUEST = {
  description: "A participant resume request",
  type: :object,
  properties: {
    data: {
      description: "A participant resume request data",
      type: :object,
      required: %i[type attributes],
      properties: {
        type: {
          description: "The data typed",
          type: :string,
        },
        attributes: {
          description: "A participant resume request attributes",
          type: :object,
          properties: {
            course_identifier: {
              description: "The type of course the participant is enrolled in",
              required: true,
              nullable: false,
              type: :string,
              enum: Course::IDENTIFIERS,
            },
          },
        },
      },
    },
  },
}.freeze
