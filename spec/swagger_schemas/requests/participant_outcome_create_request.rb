PARTICIPANT_OUTCOME_CREATE_REQUEST = {
  description: "The NPQ outcome submission request",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      description: "The NPQ outcome submission request attributes",
      type: :object,
      required: %i[type attributes],
      properties: {
        type: {
          description: "The data typed",
          type: :string,
          example: "npq-outcome-confirmation",
          required: true,
        },
        attributes: {
          description: "The NPQ outcome submission request attributes",
          type: :object,
          required: %i[course_identifier state completion_date],
          properties: {
            course_identifier: {
              description: "The type of course the participant is enrolled in",
              required: true,
              nullable: false,
              type: :string,
              example: ParticipantOutcomes::Create::PERMITTED_COURSES.first,
              enum: ParticipantOutcomes::Create::PERMITTED_COURSES,
            },
            state: {
              description: "The state of the outcome (passed or failed)",
              required: true,
              nullable: false,
              type: :string,
              example: ParticipantOutcomes::Create::STATES.first,
              enum: ParticipantOutcomes::Create::STATES,
            },
            completion_date: {
              description: "The date the participant received the assessment outcome for this course",
              required: true,
              nullable: false,
              type: :string,
              example: "2021-05-13",
            },
          },
        },
      },
    },
  },
}.freeze
