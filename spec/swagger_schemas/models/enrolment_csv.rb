ENROLMENT_CSV = {
  v2: {
    description: "The details of an NPQ application",
    type: :object,
    required: %i[
      participant_id
      course_identifier
      schedule_identifier
      cohort
      npq_application_id
      eligible_for_funding
      training_status
      school_urn
      funded_place
    ],
    properties: {
      participant_id: {
        description: "The unique identifier of this NPQ participant",
        type: :string,
        example: "7a8fef46-3c43-42c0-b3d5-1ba5904ba562",
        format: "uuid",
      },
      course_identifier: {
        description: "The NPQ course the participant is enrolled in",
        type: :string,
        example: Course::IDENTIFIERS.first,
        enum: Course::IDENTIFIERS,
      },
      schedule_identifier: {
        description: "The schedule currently applied to this enrolment",
        nullable: true,
        type: :string,
        example: Schedule::IDENTIFIERS.first,
        enum: Schedule::IDENTIFIERS,
      },
      cohort: {
        description: "The value indicates which call-off contract funds this participant’s training. 2021 indicates a participant that has started, or will start, their training in the 2021/22 academic year. Providers may change an NPQ participant’s cohort up until the point of submitting a started declaration.",
        type: :string,
        nullable: true,
        example: "2022",
      },
      npq_application_id: {
        description: "The unique identifier of this NPQ application that was accepted to create this enrolment",
        type: :string,
        example: "7a8fef46-3c43-42c0-b3d5-1ba5904ba562",
        format: "uuid",
      },
      eligible_for_funding: {
        description: "Indicates whether this NPQ participant would be eligible for funding from the DfE",
        type: :boolean,
        example: true,
      },
      training_status: {
        description: "The training status of the ECF participant",
        type: :string,
        example: Application.training_statuses.keys.first,
        enum: Application.training_statuses.keys,
      },
      school_urn: {
        description: "The Unique Reference Number (URN) of the school where this NPQ participant is teaching",
        type: :string,
        example: "106286",
      },
    },
  },
}.freeze
