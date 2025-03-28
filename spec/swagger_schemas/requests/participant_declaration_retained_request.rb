PARTICIPANT_DECLARATION_RETAINED_REQUEST = {
  description: "An NPQ participant retained declaration",
  type: :object,
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
        retained-1
        retained-2
      ],
      example: "retained-1",
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
  },
  required: %i[
    participant_id
    declaration_type
    declaration_date
    course_identifier
  ],
  example: {
    participant_id: "db3a7848-7308-4879-942a-c4a70ced400a",
    declaration_type: "retained-1",
    declaration_date: "2021-05-31T02:21:32Z",
    course_identifier: Course::IDENTIFIERS.first,
  },
}.freeze
