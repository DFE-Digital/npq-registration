PARTICIPANT_CHANGE_SCHEDULE_REQUEST = {
  description: "The change schedule request for a participant",
  type: :object,
  required: %i[data],
  properties: {
    data: {
      description: "An NPQ participant change schedule request data",
      type: :object,
      required: %i[type attributes],
      properties: {
        type: {
          description: "The data typed",
          type: :string,
          example: "participant-change-schedule",
          required: true,
        },
        attributes: {
          description: "An NPQ participant change schedule request attributes",
          type: :object,
          required: %i[schedule_identifier course_identifier],
          properties: {
            schedule_identifier: {
              description: "The new schedule of the participant",
              required: true,
              nullable: false,
              type: :string,
              example: Schedule::IDENTIFIERS.grep(/ehco/).first,
              enum: Schedule::IDENTIFIERS,
            },
            course_identifier: {
              description: "The type of course the participant is enrolled in",
              required: true,
              nullable: false,
              type: :string,
              example: Course::IDENTIFIERS.grep(/coaching/).first,
              enum: Course::IDENTIFIERS,
            },
            cohort: {
              description: "Providers may change an NPQ participant's cohort up until the point of submitting a started declaration. The value indicates which call-off contract funds this participant's training. 2023 indicates a participant that has started, or will start, their training in the 2023/24 academic year.",
              required: false,
              nullable: true,
              type: :string,
              example: "2023",
            },
          },
        },
      },
    },
  },
}.freeze
