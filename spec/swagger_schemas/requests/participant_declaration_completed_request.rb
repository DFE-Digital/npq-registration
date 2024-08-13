PARTICIPANT_DECLARATION_COMPLETED_REQUEST = {
  description: "An NPQ completed participant declaration",
  type: :object,
  required: %i[
    participant_id
    declaration_type
    declaration_date
    course_identifier
    has_passed
  ],
  additionalProperties: false,
  properties: {
    participant_id: {
      description: "The unique id of the participant",
      type: :string,
      format: :uuid,
      required: true,
      nullable: false,
      example: "db3a7848-7308-4879-942a-c4a70ced400a",
    },
    declaration_type: {
      description: "The event declaration type",
      type: :string,
      required: true,
      nullable: false,
      enum: %w[
        completed
      ],
      example: "completed",
    },
    declaration_date: {
      description: "The event declaration date",
      type: :string,
      required: true,
      nullable: false,
      format: "date-time",
      example: "2021-05-31T02:21:32Z",
    },
    course_identifier: {
      description: "The type of course the participant is enrolled in",
      type: :string,
      required: true,
      nullable: false,
      enum: Course::IDENTIFIERS,
      example: Course::IDENTIFIERS.first,
    },
    has_passed: {
      description: "Whether the participant has failed or passed",
      type: :boolean,
      required: true,
      nullable: false,
      example: true,
    },
  },
  example: {
    participant_id: "db3a7848-7308-4879-942a-c4a70ced400a",
    declaration_type: "completed",
    declaration_date: "2021-05-31T02:21:32Z",
    course_identifier: Course::IDENTIFIERS.first,
    has_passed: true,
  },
}.freeze
