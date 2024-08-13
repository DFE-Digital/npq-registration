PARTICIPANT_DECLARATION = {
  v1: {
    description: "The details of a participant declaration",
    type: :object,
    required: %i[id type attributes],
    properties: {
      id: {
        "$ref": "#/components/schemas/IDAttribute",
      },
      type: {
        type: :string,
        enum: %w[
          participant-declaration
        ],
        example: "participant-declaration",
      },
      attributes: {
        required: %i[
          participant_id
          declaration_type
          declaration_date
          course_identifier
          eligible_for_payment
          voided
          state
          updated_at
        ],
        properties: {
          participant_id: {
            description: "The unique identifier of this participant declaration record",
            type: :string,
            format: :uuid,
            nullable: false,
            example: "db3a7848-7308-4879-942a-c4a70ced400a",
          },
          declaration_type: {
            description: "The event declaration type",
            type: :string,
            nullable: false,
            example: "started",
            enum: Schedule::DECLARATION_TYPES,
          },
          course_identifier: {
            description: "The NPQ course this NPQ application relates to",
            type: :string,
            nullable: false,
            example: Course::IDENTIFIERS.first,
            enum: Course::IDENTIFIERS,
          },
          declaration_date: {
            description: "The event declaration date",
            type: :string,
            nullable: false,
            example: "2021-05-31T02:22:32Z",
          },
          state: {
            description: "Indicates the state of this payment declaration",
            type: :string,
            nullable: false,
            example: "submitted",
            enum: Declaration.states.keys,
          },
          has_passed: {
            description: "Whether the participant has failed or passed",
            type: :string,
            nullable: true,
            example: nil,
          },
          voided: {
            description: "[Deprecated - use state instead] Indicates whether this declaration has been voided",
            type: :boolean,
            nullable: true,
            example: false,
          },
          eligible_for_payment: {
            description: "[Deprecated - use state instead] Indicates whether this declaration would be eligible for funding from the DfE",
            type: :boolean,
            nullable: true,
            example: true,
          },
          updated_at: {
            description: "The date the application was last updated",
            type: :string,
            nullable: false,
            format: :"date-time",
            example: "2021-05-31T02:22:32.000Z",
          },
        },
      },
    },
  },
}.tap { |h|
  h[:v2] = h[:v1].deep_dup
  h[:v2][:properties][:attributes][:required] = h[:v1][:properties][:attributes][:required].excluding(:voided, :eligible_for_payment)
  h[:v2][:properties][:attributes][:properties] = h[:v1][:properties][:attributes][:properties].excluding(:voided, :eligible_for_payment)
  h[:v3] = h[:v2].deep_dup
  h[:v3][:properties][:attributes][:properties][:statement_id] = {
    description: "Unique ID of the statement the declaration will be paid as part of",
    type: "string",
    format: "uuid",
    example: "cd3a12347-7308-4879-942a-c4a70ced400a",
    nullable: true,
  }
  h[:v3][:properties][:attributes][:properties][:clawback_statement_id] = {
    description: "Unique id of the statement to which the declaration will be clawed back on, if any",
    type: "string",
    format: "uuid",
    example: "cd3a12347-7308-4879-942a-c4a70ced400a",
    nullable: true,
  }
  h[:v3][:properties][:attributes][:properties][:uplift_paid] = {
    description: "If participant is eligible for uplift, whether it has been paid as part of this declaration",
    type: "boolean",
    example: true,
  }
  h[:v3][:properties][:attributes][:properties][:has_passed] = {
    description: "Whether the participant has failed or passed",
    type: "string", # Need update when completed
    example: nil,
    nullable: true,
  }
  h[:v3][:properties][:attributes][:properties][:lead_provider_name] = {
    description: "The name of the provider that submitted the declaration",
    type: "string",
    example: "Example Institute",
    nullable: false,
  }
  h[:v3][:properties][:attributes][:properties][:ineligible_for_funding_reason] = {
    description: "If the declaration is ineligible, the reason why",
    type: "string",
    enum: %w[
      duplicate_declaration
    ],
    nullable: true,
    example: "duplicate_declaration",
  }
  h[:v3][:properties][:attributes][:properties][:created_at] = {
    description: "The date the application was created",
    type: :string,
    nullable: false,
    format: :"date-time",
    example: "2021-05-31T02:22:32.000Z",
  }
  # Re-add updated_at to fix ordering
  updated_at = h[:v3][:properties][:attributes][:properties].delete(:updated_at)
  h[:v3][:properties][:attributes][:properties][:updated_at] = updated_at
}.freeze
