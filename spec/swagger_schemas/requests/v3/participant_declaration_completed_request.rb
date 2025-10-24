V3_PARTICIPANT_DECLARATION_COMPLETED_REQUEST = {
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
    delivery_partner_id: {
      description: "The delivery partner ID",
      type: :string,
      format: :uuid,
      required: false,
      nullable: false,
      example: "524df095-f9bf-4f9d-ba4c-772545a99e60",
    },
    secondary_delivery_partner_id: {
      description: "The secondary delivery partner ID",
      type: :string,
      format: :uuid,
      required: false,
      nullable: false,
      example: "f0de7abf-399b-4e68-83de-2c33b503810c",
    },
    application_id: {
      description: "ID of application for declaration",
      type: :string,
      required: false,
      nullable: true,
      example: "e0f75093-d9b9-4984-b4af-d3f4ac05c515",
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
