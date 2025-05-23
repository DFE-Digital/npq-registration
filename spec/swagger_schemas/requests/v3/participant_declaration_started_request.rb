V3_PARTICIPANT_DECLARATION_STARTED_REQUEST = {
  description: "An NPQ started participant declaration",
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
        started
      ],
      example: "started",
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
  },
  required: %i[
    participant_id
    declaration_type
    declaration_date
    course_identifier
  ],
  example: {
    participant_id: "db3a7848-7308-4879-942a-c4a70ced400a",
    declaration_type: "started",
    declaration_date: "2021-05-31T02:21:32Z",
    course_identifier: Course::IDENTIFIERS.first,
    delivery_partner_id: "524df095-f9bf-4f9d-ba4c-772545a99e60",
  },
}.freeze
