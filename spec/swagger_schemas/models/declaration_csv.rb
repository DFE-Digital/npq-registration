DECLARATION_CSV = {
  v1: {
    description: "Retrieve all participant declarations in CSV format",
    type: :object,
    required: %i[
      id
      participant_id
      declaration_type
      course_identifier
      declaration_date
      state
      has_passed
      voided
      eligible_for_payment
      updated_at
    ],
    properties: {
      id: {
        description: "The unique identifier of the participant declaration record",
        type: :string,
        example: "7a8fef46-3c43-42c0-b3d5-1ba5904ba562",
        format: "uuid",
      },
      participant_id: {
        description: "The unique identifier of the participant record the declaration refers to",
        type: :string,
        example: "7a8fef46-3c43-42c0-b3d5-1ba5904ba562",
        format: "uuid",
      },
      declaration_type: {
        description: "The event declaration type",
        type: :string,
        example: Declaration.declaration_types.keys.first,
        enum: Declaration.declaration_types.keys,
      },
      course_identifier: {
        description: "The NPQ course the participant is enrolled in",
        type: :string,
        example: Course::IDENTIFIERS.first,
        enum: Course::IDENTIFIERS,
      },
      declaration_date: {
        description: "The event declaration date",
        type: :string,
        format: :"date-time",
        example: "2021-05-31T02:22:32.000Z",
      },
      state: {
        description: "Indicates the state of this payment declaration",
        type: :string,
        example: Declaration.states.keys.first,
        enum: Declaration.states.keys,
      },
      has_passed: {
        description: "Whether the participant has failed or passed",
        type: :boolean,
        example: true,
      },
      voided: {
        description: "[Deprecated - use state instead] Indicates whether this declaration has been voided",
        type: :boolean,
        example: true,
      },
      eligible_for_payment: {
        description: "[Deprecated - use state instead] Indicates whether this declaration would be eligible for funding from the DfE",
        type: :boolean,
        example: true,
      },
      updated_at: {
        description: "The date the declaration was last updated",
        type: :string,
        format: :"date-time",
        example: "2021-05-31T02:22:32.000Z",
      },
    },
  },
}.tap { |h|
  h[:v2] = h[:v1].deep_dup
  h[:v2][:required] = h[:v2][:required].excluding(:voided, :eligible_for_payment)
  h[:v2][:properties] = h[:v2][:properties].except(:voided, :eligible_for_payment)
}.freeze
